const pool = require('../config/db');

async function findById(id) {
  const result = await pool.query(
    'SELECT * FROM diary_entries WHERE id = $1',
    [id]
  );
  return result.rows[0] || null;
}

// Koristi prosleđeni klijent — deo je transakcije u diaryService.js
// (diary unos + watched_movies upsert moraju uspeti zajedno).
async function createWithClient(client, { userId, movieId, watchedDate, isRewatch, note }) {
  const result = await client.query(
    `INSERT INTO diary_entries (user_id, movie_id, watched_date, is_rewatch, note)
     VALUES ($1, $2, COALESCE($3, CURRENT_DATE), $4, $5)
     RETURNING *`,
    [userId, movieId, watchedDate || null, isRewatch || false, note || null]
  );
  return result.rows[0];
}

// Da li već postoji watched_movies zapis — koristi se pre upsert-a.
async function watchedRecordExists(client, userId, movieId) {
  const result = await client.query(
    'SELECT 1 FROM watched_movies WHERE user_id = $1 AND movie_id = $2',
    [userId, movieId]
  );
  return result.rowCount > 0;
}

async function insertWatchedRecord(client, userId, movieId, watchedAt) {
  await client.query(
    `INSERT INTO watched_movies (user_id, movie_id, watched_at)
     VALUES ($1, $2, COALESCE($3, now()))
     ON CONFLICT (user_id, movie_id) DO NOTHING`,
    [userId, movieId, watchedAt || null]
  );
}

// Dnevnik korisnika, hronološki (najnoviji prvo), sa osnovnim podacima
// o filmu — koristi se za GET /api/diary i GET /api/users/:id/diary.
async function findAllForUser(userId, { limit = 20, offset = 0 } = {}) {
  const result = await pool.query(
    `SELECT d.id, d.watched_date, d.is_rewatch, d.note, d.created_at,
            m.id AS movie_id, m.title, m.release_year, m.poster_url
     FROM diary_entries d
     JOIN movies m ON m.id = d.movie_id
     WHERE d.user_id = $1
     ORDER BY d.watched_date DESC, d.created_at DESC
     LIMIT $2 OFFSET $3`,
    [userId, limit, offset]
  );
  return result.rows;
}

async function update(id, { watchedDate, isRewatch, note }) {
  const result = await pool.query(
    `UPDATE diary_entries SET
       watched_date = COALESCE($1, watched_date),
       is_rewatch = COALESCE($2, is_rewatch),
       note = COALESCE($3, note)
     WHERE id = $4
     RETURNING *`,
    [watchedDate, isRewatch, note, id]
  );
  return result.rows[0];
}

async function remove(id) {
  await pool.query('DELETE FROM diary_entries WHERE id = $1', [id]);
}

module.exports = {
  findById,
  createWithClient,
  watchedRecordExists,
  insertWatchedRecord,
  findAllForUser,
  update,
  remove,
};
