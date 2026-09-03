const pool = require('../config/db');

async function findByUserAndMovie(userId, movieId) {
  const result = await pool.query(
    'SELECT * FROM movie_likes WHERE user_id = $1 AND movie_id = $2',
    [userId, movieId]
  );
  return result.rows[0] || null;
}

async function likeMovie(userId, movieId) {
  const result = await pool.query(
    `INSERT INTO movie_likes (user_id, movie_id)
     VALUES ($1, $2)
     RETURNING *`,
    [userId, movieId]
  );
  return result.rows[0];
}

async function unlikeMovie(userId, movieId) {
  await pool.query(
    'DELETE FROM movie_likes WHERE user_id = $1 AND movie_id = $2',
    [userId, movieId]
  );
}

// Svi filmovi koje je korisnik lajkovao — koristi se za
// GET /api/users/:id/likes (profil meni: "Likes").
async function findAllForUser(userId) {
  const result = await pool.query(
    `SELECT l.created_at, m.id AS movie_id, m.title, m.poster_url, m.release_year
     FROM movie_likes l
     JOIN movies m ON m.id = l.movie_id
     WHERE l.user_id = $1
     ORDER BY l.created_at DESC`,
    [userId]
  );
  return result.rows;
}

module.exports = {
  findByUserAndMovie,
  likeMovie,
  unlikeMovie,
  findAllForUser,
};