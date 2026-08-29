const pool = require("../config/db");

// Jedan korisnik može imati samo jednu ocenu po filmu (UNIQUE constraint
// u bazi) — ova funkcija se koristi da proverimo da li ocena već postoji
// pre nego što dozvolimo kreiranje nove.
async function findByUserAndMovie(userId, movieId) {
  const result = await pool.query(
    "SELECT * FROM ratings WHERE user_id = $1 AND movie_id = $2",
    [userId, movieId],
  );
  return result.rows[0] || null;
}

async function findById(id) {
  const result = await pool.query("SELECT * FROM ratings WHERE id = $1", [id]);
  return result.rows[0] || null;
}

async function create({ userId, movieId, rating }) {
  const result = await pool.query(
    `INSERT INTO ratings (user_id, movie_id, rating)
     VALUES ($1, $2, $3)
     RETURNING *`,
    [userId, movieId, rating],
  );
  return result.rows[0];
}

async function update(id, rating) {
  const result = await pool.query(
    `UPDATE ratings SET rating = $1 WHERE id = $2 RETURNING *`,
    [rating, id],
  );
  return result.rows[0];
}

async function remove(id) {
  await pool.query("DELETE FROM ratings WHERE id = $1", [id]);
}

// Sve ocene za jedan film, sa username-om ocenjivača — koristi se za
// GET /api/ratings/movie/:movieId
async function findAllForMovie(movieId) {
  const result = await pool.query(
    `SELECT r.id, r.rating, r.created_at, u.id AS user_id, u.username, u.avatar_url
     FROM ratings r
     JOIN users u ON u.id = r.user_id
     WHERE r.movie_id = $1
     ORDER BY r.created_at DESC`,
    [movieId],
  );
  return result.rows;
}

module.exports = {
  findByUserAndMovie,
  findById,
  create,
  update,
  remove,
  findAllForMovie,
};
