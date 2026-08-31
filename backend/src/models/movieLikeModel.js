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

module.exports = {
  findByUserAndMovie,
  likeMovie,
  unlikeMovie,
};
