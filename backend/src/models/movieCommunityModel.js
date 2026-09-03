const pool = require('../config/db');

async function findMembers(
  movieId,
  viewerUserId,
  { limit = 100, offset = 0 } = {}
) {
  const [dataResult, countResult] = await Promise.all([
    pool.query(
      `
        SELECT
          u.id AS user_id,
          u.username,
          u.avatar_url,
          u.bio,
          r.rating,
          w.watched_at,

          EXISTS (
            SELECT 1
            FROM follows f
            WHERE f.follower_id = $2::BIGINT
              AND f.following_id = u.id
          ) AS is_following,

          COALESCE(
            u.id = $2::BIGINT,
            false
          ) AS is_current_user

        FROM watched_movies w

        JOIN users u
          ON u.id = w.user_id

        LEFT JOIN ratings r
          ON r.user_id = w.user_id
         AND r.movie_id = w.movie_id

        WHERE w.movie_id = $1

        ORDER BY
          CASE
            WHEN u.id = $2::BIGINT THEN 0

            WHEN EXISTS (
              SELECT 1
              FROM follows f
              WHERE f.follower_id = $2::BIGINT
                AND f.following_id = u.id
            ) THEN 1

            ELSE 2
          END,

          w.watched_at DESC,
          u.username ASC

        LIMIT $3
        OFFSET $4
      `,
      [
        movieId,
        viewerUserId || null,
        limit,
        offset,
      ]
    ),

    pool.query(
      `
        SELECT COUNT(*) AS total

        FROM watched_movies

        WHERE movie_id = $1
      `,
      [movieId]
    ),
  ]);

  return {
    members: dataResult.rows,

    total: Number.parseInt(
      countResult.rows[0].total,
      10
    ),
  };
}

async function findListsContainingMovie(
  movieId,
  {
    limit = 50,
    offset = 0,
  } = {}
) {
  const [dataResult, countResult] =
    await Promise.all([
      pool.query(
        `
          SELECT
            l.id,
            l.name,
            l.description,
            l.is_public,
            l.created_at,

            u.id AS user_id,
            u.username,
            u.avatar_url,

            (
              SELECT COUNT(*)

              FROM list_movies all_items

              WHERE
                all_items.list_id = l.id
            ) AS movie_count,

            ARRAY(
              SELECT
                m2.poster_url

              FROM list_movies preview_items

              JOIN movies m2
                ON m2.id =
                   preview_items.movie_id

              WHERE
                preview_items.list_id = l.id

                AND m2.poster_url
                    IS NOT NULL

              ORDER BY
                preview_items.position ASC

              LIMIT 4
            ) AS poster_urls

          FROM list_movies contains_movie

          JOIN movie_lists l
            ON l.id =
               contains_movie.list_id

          JOIN users u
            ON u.id =
               l.user_id

          WHERE
            contains_movie.movie_id = $1

            AND l.is_public = true

          ORDER BY
            l.created_at DESC

          LIMIT $2
          OFFSET $3
        `,
        [
          movieId,
          limit,
          offset,
        ]
      ),

      pool.query(
        `
          SELECT
            COUNT(*) AS total

          FROM list_movies contains_movie

          JOIN movie_lists l
            ON l.id =
               contains_movie.list_id

          WHERE
            contains_movie.movie_id = $1

            AND l.is_public = true
        `,
        [movieId]
      ),
    ]);

  return {
    lists: dataResult.rows,

    total: Number.parseInt(
      countResult.rows[0].total,
      10
    ),
  };
}

module.exports = {
  findMembers,
  findListsContainingMovie,
};