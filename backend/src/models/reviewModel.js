const pool = require('../config/db');

async function findByUserAndMovie(
  userId,
  movieId
) {
  const result =
    await pool.query(
      `
        SELECT *

        FROM reviews

        WHERE
          user_id = $1
          AND movie_id = $2

        ORDER BY
          created_at DESC

        LIMIT 1
      `,
      [
        userId,
        movieId,
      ]
    );

  return (
    result.rows[0] ||
    null
  );
}

async function findById(id) {
  const result =
    await pool.query(
      `
        SELECT

          r.id,

          r.user_id,

          r.movie_id,

          r.diary_entry_id,

          r.content,

          r.is_spoiler,

          r.tags,

          r.comments_enabled,

          r.created_at,

          r.updated_at,

          u.username,

          u.avatar_url,

          COUNT(rl.id)
            AS like_count

        FROM reviews r

        JOIN users u
          ON u.id =
             r.user_id

        LEFT JOIN review_likes rl
          ON rl.review_id =
             r.id

        WHERE
          r.id = $1

        GROUP BY
          r.id,
          u.username,
          u.avatar_url
      `,
      [id]
    );

  return (
    result.rows[0] ||
    null
  );
}

async function create({
  userId,
  movieId,
  content,
  isSpoiler = false,
  tags = [],
  commentsEnabled = true,
  diaryEntryId = null,
}) {
  const result =
    await pool.query(
      `
        INSERT INTO reviews (
          user_id,
          movie_id,
          diary_entry_id,
          content,
          is_spoiler,
          tags,
          comments_enabled
        )

        VALUES (
          $1,
          $2,
          $3,
          $4,
          $5,
          $6,
          $7
        )

        RETURNING *
      `,
      [
        userId,
        movieId,
        diaryEntryId,
        content,
        isSpoiler,
        tags,
        commentsEnabled,
      ]
    );

  return result.rows[0];
}

async function createWithClient(
  client,
  {
    userId,
    movieId,
    content,
    isSpoiler = false,
    tags = [],
    commentsEnabled = true,
    diaryEntryId = null,
  }
) {
  const result =
    await client.query(
      `
        INSERT INTO reviews (
          user_id,
          movie_id,
          diary_entry_id,
          content,
          is_spoiler,
          tags,
          comments_enabled
        )

        VALUES (
          $1,
          $2,
          $3,
          $4,
          $5,
          $6,
          $7
        )

        RETURNING *
      `,
      [
        userId,
        movieId,
        diaryEntryId,
        content,
        isSpoiler,
        tags,
        commentsEnabled,
      ]
    );

  return result.rows[0];
}

async function update(
  id,
  {
    content,
    isSpoiler,
    tags,
    commentsEnabled,
  }
) {
  const result =
    await pool.query(
      `
        UPDATE reviews

        SET
          content =
            COALESCE(
              $1,
              content
            ),

          is_spoiler =
            COALESCE(
              $2,
              is_spoiler
            ),

          tags =
            COALESCE(
              $3,
              tags
            ),

          comments_enabled =
            COALESCE(
              $4,
              comments_enabled
            )

        WHERE
          id = $5

        RETURNING *
      `,
      [
        content,
        isSpoiler,
        tags,
        commentsEnabled,
        id,
      ]
    );

  return result.rows[0];
}

async function remove(id) {
  await pool.query(
    `
      DELETE FROM reviews
      WHERE id = $1
    `,
    [id]
  );
}

function movieReviewFilterClause(
  filter,
  viewerUserId
) {
  if (filter === 'everyone') {
    return '';
  }

  if (!viewerUserId) {
    return 'AND FALSE';
  }

  const clauses = {
    friends: `
      AND EXISTS (
        SELECT 1

        FROM follows f

        WHERE
          f.follower_id = $2
          AND f.following_id =
              r.user_id
      )
    `,

    you: `
      AND r.user_id = $2
    `,

    liked: `
      AND EXISTS (
        SELECT 1

        FROM review_likes my_like

        WHERE
          my_like.review_id = r.id
          AND my_like.user_id = $2
      )
    `,
  };

  return (
    clauses[filter] ||
    ''
  );
}

async function findAllForMovie(
  movieId,
  {
    sortBy = 'newest',
    filter = 'everyone',
    viewerUserId = null,
    limit = 50,
  } = {}
) {
  const orderClause =
    sortBy === 'mostLiked'
      ? 'like_count DESC, r.created_at DESC'
      : 'r.created_at DESC';

  const filterClause =
    movieReviewFilterClause(
      filter,
      viewerUserId
    );

  const result =
    await pool.query(
      `
        SELECT

          r.id,

          r.user_id,

          r.diary_entry_id,

          r.content,

          r.is_spoiler,

          r.tags,

          r.comments_enabled,

          r.created_at,

          r.updated_at,

          u.username,

          u.avatar_url,

          COALESCE(
            d.rating,
            current_rating.rating
          ) AS rating,

          COALESCE(
            d.is_rewatch,
            false
          ) AS is_rewatch,

          EXISTS (
            SELECT 1

            FROM movie_likes ml

            WHERE
              ml.user_id =
                r.user_id

              AND ml.movie_id =
                  r.movie_id
          ) AS liked_movie,

          (
            SELECT COUNT(*)

            FROM review_likes rl

            WHERE
              rl.review_id = r.id
          ) AS like_count,

          EXISTS (
            SELECT 1

            FROM review_likes my_like

            WHERE
              my_like.review_id = r.id

              AND my_like.user_id = $2
          ) AS liked_by_me,

          (
            SELECT COUNT(*)

            FROM review_comments rc

            WHERE
              rc.review_id = r.id
          ) AS comment_count

        FROM reviews r

        JOIN users u
          ON u.id =
             r.user_id

        LEFT JOIN diary_entries d
          ON d.id =
             r.diary_entry_id

        LEFT JOIN ratings current_rating

          ON current_rating.user_id =
             r.user_id

          AND current_rating.movie_id =
              r.movie_id

        WHERE
          r.movie_id = $1

          ${filterClause}

        ORDER BY
          ${orderClause}

        LIMIT $3
      `,
      [
        movieId,
        viewerUserId,
        limit,
      ]
    );

  return result.rows;
}

async function findAllForUser(
  userId
) {
  const result =
    await pool.query(
      `
        SELECT

          r.id,

          r.movie_id,

          r.diary_entry_id,

          r.content,

          r.is_spoiler,

          r.tags,

          r.comments_enabled,

          r.created_at,

          r.updated_at,

          m.title,

          m.poster_url,

          m.release_year,

          COUNT(rl.id)
            AS like_count

        FROM reviews r

        JOIN movies m
          ON m.id =
             r.movie_id

        LEFT JOIN review_likes rl
          ON rl.review_id =
             r.id

        WHERE
          r.user_id = $1

        GROUP BY
          r.id,
          m.title,
          m.poster_url,
          m.release_year

        ORDER BY
          r.created_at DESC
      `,
      [userId]
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
  findAllForUser,
};