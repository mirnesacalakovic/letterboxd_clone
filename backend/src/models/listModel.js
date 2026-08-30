const pool = require('../config/db');

async function create({ userId, name, description, isPublic }) {
  const result = await pool.query(
    `INSERT INTO movie_lists (user_id, name, description, is_public)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [userId, name, description || null, isPublic !== undefined ? isPublic : true]
  );
  return result.rows[0];
}

async function findById(id) {
  const result = await pool.query(
    'SELECT * FROM movie_lists WHERE id = $1',
    [id]
  );
  return result.rows[0] || null;
}

// Sve liste jednog korisnika. Ako includePrivate nije true, vraća
// samo javne liste (koristi se kad neko drugi gleda tuđ profil).
async function findAllForUser(userId, { includePrivate = false } = {}) {
  const query = includePrivate
    ? 'SELECT * FROM movie_lists WHERE user_id = $1 ORDER BY created_at DESC'
    : 'SELECT * FROM movie_lists WHERE user_id = $1 AND is_public = true ORDER BY created_at DESC';
  const result = await pool.query(query, [userId]);
  return result.rows;
}

async function update(id, { name, description, isPublic }) {
  const result = await pool.query(
    `UPDATE movie_lists SET
       name = COALESCE($1, name),
       description = COALESCE($2, description),
       is_public = COALESCE($3, is_public)
     WHERE id = $4
     RETURNING *`,
    [name, description, isPublic, id]
  );
  return result.rows[0];
}

async function remove(id) {
  await pool.query('DELETE FROM movie_lists WHERE id = $1', [id]);
}

// Filmovi u listi, sortirani po position vrednosti (NUMERIC, videti
// napomenu u schema.sql o razlogu za NUMERIC umesto INTEGER).
async function findMoviesInList(listId) {
  const result = await pool.query(
    `SELECT lm.position, lm.added_at, m.id AS movie_id, m.title, m.release_year, m.poster_url
     FROM list_movies lm
     JOIN movies m ON m.id = lm.movie_id
     WHERE lm.list_id = $1
     ORDER BY lm.position ASC`,
    [listId]
  );
  return result.rows;
}

async function findMovieInList(listId, movieId) {
  const result = await pool.query(
    'SELECT * FROM list_movies WHERE list_id = $1 AND movie_id = $2',
    [listId, movieId]
  );
  return result.rows[0] || null;
}

// Sledeća pozicija = trenutni max + 1 (ili 1 ako je lista prazna).
// Novi filmovi se uvek dodaju na kraj liste.
async function getNextPosition(listId) {
  const result = await pool.query(
    'SELECT COALESCE(MAX(position), 0) + 1 AS next_position FROM list_movies WHERE list_id = $1',
    [listId]
  );
  return result.rows[0].next_position;
}

async function addMovie(listId, movieId, position) {
  const result = await pool.query(
    `INSERT INTO list_movies (list_id, movie_id, position)
     VALUES ($1, $2, $3)
     RETURNING *`,
    [listId, movieId, position]
  );
  return result.rows[0];
}

async function removeMovie(listId, movieId) {
  await pool.query(
    'DELETE FROM list_movies WHERE list_id = $1 AND movie_id = $2',
    [listId, movieId]
  );
}

// Sve javne liste SVIH korisnika (ne samo trenutnog) — za "Discover"
// pregled. sortBy: 'newest' (default) ili 'movieCount'.
async function findAllPublic({ limit = 20, offset = 0, sortBy = 'newest' }) {
  const sortColumn = {
    newest: 'l.created_at DESC',
    movieCount: 'movie_count DESC',
  }[sortBy] || 'l.created_at DESC';

  const result = await pool.query(
    `SELECT l.id, l.name, l.description, l.created_at,
            u.id AS user_id, u.username, u.avatar_url,
            COUNT(lm.movie_id) AS movie_count
     FROM movie_lists l
     JOIN users u ON u.id = l.user_id
     LEFT JOIN list_movies lm ON lm.list_id = l.id
     WHERE l.is_public = true
     GROUP BY l.id, u.id
     ORDER BY ${sortColumn}
     LIMIT $1 OFFSET $2`,
    [limit, offset]
  );
  return result.rows;
}

module.exports = {
  create,
  findById,
  findAllForUser,
  findAllPublic,
  update,
  remove,
  findMoviesInList,
  findMovieInList,
  getNextPosition,
  addMovie,
  removeMovie,
};
