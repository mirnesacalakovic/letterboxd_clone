const pool = require('../config/db');

async function getState(userId, movieId) {
  const result = await pool.query(
    `SELECT
       EXISTS(SELECT 1 FROM movies WHERE id = $2) AS movie_exists,
       (SELECT rating FROM ratings WHERE user_id = $1 AND movie_id = $2) AS rating,
       EXISTS(SELECT 1 FROM movie_likes WHERE user_id = $1 AND movie_id = $2) AS liked,
       EXISTS(SELECT 1 FROM watched_movies WHERE user_id = $1 AND movie_id = $2) AS has_watched`,
    [userId, movieId]
  );

  const row = result.rows[0];

  return {
    movieExists: row.movie_exists,
    rating: row.rating === null ? null : Number(row.rating),
    liked: row.liked,
    hasWatched: row.has_watched,
  };
}

async function ensureMovieExists(client, movieId) {
  const result = await client.query(
    'SELECT 1 FROM movies WHERE id = $1',
    [movieId]
  );

  if (result.rowCount === 0) {
    const error = new Error('Film ne postoji');
    error.code = 'MOVIE_NOT_FOUND';
    throw error;
  }
}

async function createDiaryEntry(client, data) {
  const result = await client.query(
    `INSERT INTO diary_entries
       (user_id, movie_id, watched_date, is_rewatch, rating, tags)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING *`,
    [
      data.userId,
      data.movieId,
      data.watchedDate,
      data.isRewatch,
      data.rating,
      data.tags,
    ]
  );

  return result.rows[0];
}

async function markWatched(
  client,
  { userId, movieId, watchedDate }
) {
  await client.query(
    `INSERT INTO watched_movies
       (user_id, movie_id, watched_at)
     VALUES ($1, $2, $3::date)
     ON CONFLICT (user_id, movie_id)
     DO NOTHING`,
    [userId, movieId, watchedDate]
  );
}

async function setRating(
  client,
  { userId, movieId, rating }
) {
  if (rating === null) {
    await client.query(
      `DELETE FROM ratings
       WHERE user_id = $1
       AND movie_id = $2`,
      [userId, movieId]
    );

    return null;
  }

  const result = await client.query(
    `INSERT INTO ratings
       (user_id, movie_id, rating)
     VALUES ($1, $2, $3)

     ON CONFLICT (user_id, movie_id)
     DO UPDATE SET
       rating = EXCLUDED.rating,
       updated_at = now()

     RETURNING *`,
    [userId, movieId, rating]
  );

  return result.rows[0];
}

async function setMovieLike(
  client,
  { userId, movieId, liked }
) {
  if (liked) {
    await client.query(
      `INSERT INTO movie_likes
         (user_id, movie_id)
       VALUES ($1, $2)

       ON CONFLICT (user_id, movie_id)
       DO NOTHING`,
      [userId, movieId]
    );

    return;
  }

  await client.query(
    `DELETE FROM movie_likes
     WHERE user_id = $1
     AND movie_id = $2`,
    [userId, movieId]
  );
}

async function saveReview(
  client,
  data,
  diaryEntryId
) {
  if (!data.review) {
    return null;
  }

  const result = await client.query(
    `INSERT INTO reviews
       (
         user_id,
         movie_id,
         diary_entry_id,
         content,
         is_spoiler,
         tags,
         comments_enabled
       )
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING *`,
    [
      data.userId,
      data.movieId,
      diaryEntryId,
      data.review,
      data.isSpoiler,
      data.tags,
      data.commentsAllowed,
    ]
  );

  return result.rows[0];
}

async function logFilm(data) {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    await ensureMovieExists(
      client,
      data.movieId
    );

    const entry =
      await createDiaryEntry(
        client,
        data
      );

    await markWatched(
      client,
      data
    );

    const rating =
      await setRating(
        client,
        data
      );

    await setMovieLike(
      client,
      data
    );

    const review =
      await saveReview(
        client,
        data,
        entry.id
      );

    await client.query('COMMIT');

    return {
      entry,
      rating,
      review,
      liked: data.liked,
    };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

module.exports = {
  getState,
  logFilm,
};