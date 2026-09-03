const pool =
  require('../config/db');

async function findById(id) {
  const result =
    await pool.query(
      `SELECT *
       FROM diary_entries
       WHERE id = $1`,
      [id]
    );

  return result.rows[0] || null;
}

// Koristi prosleđeni client kada je diary
// deo veće transakcije.
async function createWithClient(
  client,
  {
    userId,
    movieId,
    watchedDate,
    isRewatch,
    note,
    rating = null,
    tags = [],
  }
) {
  const result =
    await client.query(
      `INSERT INTO diary_entries
         (
           user_id,
           movie_id,
           watched_date,
           is_rewatch,
           note,
           rating,
           tags
         )
       VALUES (
         $1,
         $2,
         COALESCE($3, CURRENT_DATE),
         $4,
         $5,
         $6,
         $7
       )
       RETURNING *`,
      [
        userId,
        movieId,
        watchedDate || null,
        isRewatch || false,
        note || null,
        rating,
        tags,
      ]
    );

  return result.rows[0];
}

async function watchedRecordExists(
  client,
  userId,
  movieId
) {
  const result =
    await client.query(
      `SELECT 1
       FROM watched_movies
       WHERE user_id = $1
       AND movie_id = $2`,
      [
        userId,
        movieId,
      ]
    );

  return result.rowCount > 0;
}

async function insertWatchedRecord(
  client,
  userId,
  movieId,
  watchedAt
) {
  await client.query(
    `INSERT INTO watched_movies
       (
         user_id,
         movie_id,
         watched_at
       )
     VALUES (
       $1,
       $2,
       COALESCE($3, now())
     )

     ON CONFLICT
       (user_id, movie_id)
     DO NOTHING`,
    [
      userId,
      movieId,
      watchedAt || null,
    ]
  );
}

// Novi diary unos čuva svoj rating snapshot.
// Za stare unose iz seeda rating je NULL,
// pa kao fallback čitamo current rating.
async function findAllForUser(
  userId,
  {
    limit = 20,
    offset = 0,
  } = {}
) {
  const result =
    await pool.query(
      `SELECT
         d.id,
         d.watched_date,
         d.is_rewatch,
         d.note,
         d.tags,
         d.created_at,

         m.id AS movie_id,
         m.title,
         m.release_year,
         m.poster_url,

         COALESCE(
           d.rating,
           r.rating
         ) AS rating

       FROM diary_entries d

       JOIN movies m
         ON m.id = d.movie_id

       LEFT JOIN ratings r
         ON r.user_id = d.user_id
        AND r.movie_id = d.movie_id

       WHERE d.user_id = $1

       ORDER BY
         d.watched_date DESC,
         d.created_at DESC

       LIMIT $2
       OFFSET $3`,
      [
        userId,
        limit,
        offset,
      ]
    );

  return result.rows;
}

async function update(
  id,
  {
    watchedDate,
    isRewatch,
    note,
  }
) {
  const result =
    await pool.query(
      `UPDATE diary_entries
       SET
         watched_date =
           COALESCE(
             $1,
             watched_date
           ),

         is_rewatch =
           COALESCE(
             $2,
             is_rewatch
           ),

         note =
           COALESCE(
             $3,
             note
           )

       WHERE id = $4

       RETURNING *`,
      [
        watchedDate,
        isRewatch,
        note,
        id,
      ]
    );

  return result.rows[0];
}

async function remove(id) {
  await pool.query(
    `DELETE FROM diary_entries
     WHERE id = $1`,
    [id]
  );
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