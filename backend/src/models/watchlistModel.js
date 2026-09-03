const pool = require('../config/db');

async function findByUserAndMovie(userId, movieId) {
  const result = await pool.query(
    'SELECT * FROM watchlist WHERE user_id = $1 AND movie_id = $2',
    [userId, movieId]
  );
  return result.rows[0] || null;
}

async function addToWatchlist(userId, movieId) {
  const result = await pool.query(
    `INSERT INTO watchlist (user_id, movie_id)
     VALUES ($1, $2)
     RETURNING *`,
    [userId, movieId]
  );
  return result.rows[0];
}

async function removeFromWatchlist(userId, movieId) {
  await pool.query(
    'DELETE FROM watchlist WHERE user_id = $1 AND movie_id = $2',
    [userId, movieId]
  );
}

// Cela watchlist korisnika, sa osnovnim podacima o filmu — koristi se
// za GET /api/watchlist (profil / "Watchlist" tab). Isti obrazac kao
// watchedModel.findAllForUser.
async function findAllForUser(userId) {
  const result = await pool.query(
    `SELECT w.id, w.created_at, m.id AS movie_id, m.title, m.release_year, m.poster_url
     FROM watchlist w
     JOIN movies m ON m.id = w.movie_id
     WHERE w.user_id = $1
     ORDER BY w.created_at DESC`,
    [userId]
  );
  return result.rows;
}

module.exports = {
  findByUserAndMovie,
  addToWatchlist,
  removeFromWatchlist,
  findAllForUser,
};