const pool = require('../config/db');

// Jedan korisnik ima najviše jednu recenziju po filmu (UNIQUE constraint).
async function findByUserAndMovie(userId, movieId) {
  const result = await pool.query(
    'SELECT * FROM reviews WHERE user_id = $1 AND movie_id = $2',
    [userId, movieId]
  );
  return result.rows[0] || null;
}

// Detalji jedne recenzije, sa username-om autora i brojem lajkova —
// koristi se za GET /api/reviews/:id.
async function findById(id) {
  const result = await pool.query(
    `SELECT r.id, r.user_id, r.movie_id, r.content, r.is_spoiler, r.tags,
            r.created_at, r.updated_at,
            u.username, u.avatar_url,
            COUNT(rl.id) AS like_count
     FROM reviews r
     JOIN users u ON u.id = r.user_id
     LEFT JOIN review_likes rl ON rl.review_id = r.id
     WHERE r.id = $1
     GROUP BY r.id, u.username, u.avatar_url`,
    [id]
  );
  return result.rows[0] || null;
}

async function create({ userId, movieId, content, isSpoiler = false, tags = [] }) {
  const result = await pool.query(
    `INSERT INTO reviews (user_id, movie_id, content, is_spoiler, tags)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [userId, movieId, content, isSpoiler, tags]
  );
  return result.rows[0];
}

// Isto kao create, ali koristi prosleđeni klijent (deo transakcije) —
// koristi se za kombinovan unos rating+review, gde oba insert-a moraju
// uspeti zajedno ili nijedan (videti reviewService.createWithRating).
async function createWithClient(client, { userId, movieId, content, isSpoiler = false, tags = [] }) {
  const result = await client.query(
    `INSERT INTO reviews (user_id, movie_id, content, is_spoiler, tags)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [userId, movieId, content, isSpoiler, tags]
  );
  return result.rows[0];
}

async function update(id, { content, isSpoiler, tags }) {
  const result = await pool.query(
    `UPDATE reviews SET
       content = COALESCE($1, content),
       is_spoiler = COALESCE($2, is_spoiler),
       tags = COALESCE($3, tags)
     WHERE id = $4
     RETURNING *`,
    [content, isSpoiler, tags, id]
  );
  return result.rows[0];
}

async function remove(id) {
  await pool.query('DELETE FROM reviews WHERE id = $1', [id]);
}

// Sve recenzije za jedan film, sa username-om autora i brojem lajkova —
// koristi se za GET /api/movies/:id/reviews.
async function findAllForMovie(movieId) {
  const result = await pool.query(
    `SELECT r.id, r.user_id, r.content, r.is_spoiler, r.tags,
            r.created_at, r.updated_at,
            u.username, u.avatar_url,
            COUNT(rl.id) AS like_count
     FROM reviews r
     JOIN users u ON u.id = r.user_id
     LEFT JOIN review_likes rl ON rl.review_id = r.id
     WHERE r.movie_id = $1
     GROUP BY r.id, u.username, u.avatar_url
     ORDER BY r.created_at DESC`,
    [movieId]
  );
  return result.rows;
}

module.exports = {
  findByUserAndMovie,
  findById,
  create,
  createWithClient,
  update,
  remove,
  findAllForMovie,
};