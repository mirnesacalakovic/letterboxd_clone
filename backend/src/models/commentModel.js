const pool = require('../config/db');

async function findById(id) {
  const result = await pool.query(
    'SELECT * FROM review_comments WHERE id = $1',
    [id]
  );
  return result.rows[0] || null;
}

async function create({ reviewId, userId, content }) {
  const result = await pool.query(
    `INSERT INTO review_comments (review_id, user_id, content)
     VALUES ($1, $2, $3)
     RETURNING *`,
    [reviewId, userId, content]
  );
  return result.rows[0];
}

// Svi komentari za jednu recenziju, sa username-om autora komentara.
async function findAllForReview(reviewId) {
  const result = await pool.query(
    `SELECT c.id, c.review_id, c.content, c.created_at, c.updated_at,
            u.id AS user_id, u.username, u.avatar_url
     FROM review_comments c
     JOIN users u ON u.id = c.user_id
     WHERE c.review_id = $1
     ORDER BY c.created_at ASC`,
    [reviewId]
  );
  return result.rows;
}

async function update(id, content) {
  const result = await pool.query(
    'UPDATE review_comments SET content = $1 WHERE id = $2 RETURNING *',
    [content, id]
  );
  return result.rows[0];
}

async function remove(id) {
  await pool.query('DELETE FROM review_comments WHERE id = $1', [id]);
}

module.exports = {
  findById,
  create,
  findAllForReview,
  update,
  remove,
};
