const pool = require('../config/db');

async function findByUserAndReview(userId, reviewId) {
  const result = await pool.query(
    'SELECT * FROM review_likes WHERE user_id = $1 AND review_id = $2',
    [userId, reviewId]
  );
  return result.rows[0] || null;
}

async function likeReview(userId, reviewId) {
  const result = await pool.query(
    `INSERT INTO review_likes (user_id, review_id)
     VALUES ($1, $2)
     RETURNING *`,
    [userId, reviewId]
  );
  return result.rows[0];
}

async function unlikeReview(userId, reviewId) {
  await pool.query(
    'DELETE FROM review_likes WHERE user_id = $1 AND review_id = $2',
    [userId, reviewId]
  );
}

module.exports = {
  findByUserAndReview,
  likeReview,
  unlikeReview,
};
