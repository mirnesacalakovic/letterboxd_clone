const pool = require('../config/db');

async function findByUserAndMovie(userId, movieId) {
  const result = await pool.query(
    'SELECT * FROM watched_movies WHERE user_id = $1 AND movie_id = $2',
    [userId, movieId]
  );
  return result.rows[0] || null;
}

async function markAsWatched(userId, movieId) {
  const result = await pool.query(
    `INSERT INTO watched_movies (user_id, movie_id)
     VALUES ($1, $2)
     RETURNING *`,
    [userId, movieId]
  );
  return result.rows[0];
}

async function removeWatched(userId, movieId) {
  await pool.query(
    'DELETE FROM watched_movies WHERE user_id = $1 AND movie_id = $2',
    [userId, movieId]
  );
}

// Svi pogledani filmovi korisnika, sa osnovnim podacima o filmu —
// koristi se za GET /api/watched (profil / "watched" tab).
async function findAllForUser(userId) {
  const result = await pool.query(
    `SELECT w.id, w.watched_at, m.id AS movie_id, m.title, m.release_year, m.poster_url
     FROM watched_movies w
     JOIN movies m ON m.id = w.movie_id
     WHERE w.user_id = $1
     ORDER BY w.watched_at DESC`,
    [userId]
  );
  return result.rows;
}

module.exports = {
  findByUserAndMovie,
  markAsWatched,
  removeWatched,
  findAllForUser,
};