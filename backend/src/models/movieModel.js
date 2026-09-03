const pool = require('../config/db');

const BASE_SELECT = `
  SELECT
    m.id, m.title, m.release_year, m.director, m.overview, m.runtime,
    m.actors, m.keywords, m.poster_url, m.backdrop_url,
    COALESCE(array_agg(DISTINCT g.name) FILTER (WHERE g.name IS NOT NULL), '{}') AS genres,
    ROUND(AVG(r.rating), 2) AS average_rating,
    COUNT(DISTINCT r.id) AS rating_count,
    (SELECT COUNT(*) FROM movie_likes ml WHERE ml.movie_id = m.id) AS like_count
  FROM movies m
  LEFT JOIN movie_genres mg ON mg.movie_id = m.id
  LEFT JOIN genres g ON g.id = mg.genre_id
  LEFT JOIN ratings r ON r.movie_id = m.id
`;

async function findAll({
  limit = 20,
  offset = 0,
  decade,
  minRating,
  sortBy = 'title',
}) {
  const conditions = [];
  const params = [];
  let paramIndex = 1;

  if (decade) {
    conditions.push(
      `m.release_year BETWEEN $${paramIndex} AND $${paramIndex + 1}`
    );

    params.push(
      decade,
      decade + 9
    );

    paramIndex += 2;
  }

  const whereClause =
    conditions.length
      ? `WHERE ${conditions.join(' AND ')}`
      : '';

  const havingConditions = [];

  if (minRating !== undefined) {
    havingConditions.push(
      `AVG(r.rating) >= $${paramIndex}`
    );

    params.push(minRating);
    paramIndex += 1;
  }

  const havingClause =
    havingConditions.length
      ? `HAVING ${havingConditions.join(' AND ')}`
      : '';

  const sortColumn = {
    newest:
      'm.release_year DESC NULLS LAST',

    rating:
      'average_rating DESC NULLS LAST',

    popular:
      'rating_count DESC',

    title:
      'm.title ASC',
  }[sortBy] || 'm.title ASC';

  const baseQuery = `
    ${BASE_SELECT}
    ${whereClause}
    GROUP BY m.id
    ${havingClause}
  `;

  const dataParams = [
    ...params,
    limit,
    offset,
  ];

  const limitParam =
    paramIndex;

  const offsetParam =
    paramIndex + 1;

  const [
    dataResult,
    countResult,
  ] = await Promise.all([
    pool.query(
      `
        ${baseQuery}
        ORDER BY ${sortColumn}
        LIMIT $${limitParam}
        OFFSET $${offsetParam}
      `,
      dataParams
    ),

    pool.query(
      `
        SELECT COUNT(*) AS total
        FROM (${baseQuery}) t
      `,
      params
    ),
  ]);

  return {
    movies:
      dataResult.rows,

    total:
      Number.parseInt(
        countResult.rows[0].total,
        10
      ),
  };
}

async function findById(id) {
  const result =
    await pool.query(
      `
        ${BASE_SELECT}

        WHERE m.id = $1

        GROUP BY m.id
      `,
      [id]
    );

  return (
    result.rows[0] ||
    null
  );
}

async function search(
  query,
  {
    limit = 20,
    offset = 0,
  }
) {
  const likeQuery =
    `%${query}%`;

  const baseQuery = `
    ${BASE_SELECT}

    WHERE
      m.title ILIKE $1

      OR m.director ILIKE $1

      OR EXISTS (
        SELECT 1

        FROM unnest(
          m.actors
        ) AS actor

        WHERE actor ILIKE $1
      )

      OR EXISTS (
        SELECT 1

        FROM movie_genres mg2

        JOIN genres g2
          ON g2.id =
             mg2.genre_id

        WHERE
          mg2.movie_id = m.id
          AND g2.name ILIKE $1
      )

    GROUP BY m.id
  `;

  const [
    dataResult,
    countResult,
  ] = await Promise.all([
    pool.query(
      `
        ${baseQuery}

        ORDER BY m.title ASC

        LIMIT $2
        OFFSET $3
      `,
      [
        likeQuery,
        limit,
        offset,
      ]
    ),

    pool.query(
      `
        SELECT COUNT(*) AS total
        FROM (${baseQuery}) t
      `,
      [likeQuery]
    ),
  ]);

  return {
    movies:
      dataResult.rows,

    total:
      Number.parseInt(
        countResult.rows[0].total,
        10
      ),
  };
}

async function getMovieStats(
  movieId
) {
  const result =
    await pool.query(
      `
        SELECT

          (
            SELECT
              COUNT(
                DISTINCT user_id
              )

            FROM watched_movies

            WHERE
              movie_id = $1
          ) AS members_count,

          (
            SELECT
              COUNT(*)

            FROM reviews

            WHERE
              movie_id = $1
          ) AS review_count,

          (
            SELECT
              COUNT(
                DISTINCT list_id
              )

            FROM list_movies

            WHERE
              movie_id = $1
          ) AS list_count
      `,
      [movieId]
    );

  return result.rows[0];
}

async function getRatingsDistribution(
  movieId
) {
  const result =
    await pool.query(
      `
        SELECT

          (
            steps.value / 2.0
          )::NUMERIC(2,1)
            AS rating,

          COUNT(r.id)
            AS count

        FROM generate_series(
          1,
          10
        ) AS steps(value)

        LEFT JOIN ratings r

          ON r.movie_id = $1

          AND r.rating =
            (
              steps.value / 2.0
            )

        GROUP BY
          steps.value

        ORDER BY
          steps.value ASC
      `,
      [movieId]
    );

  return result.rows;
}

async function getWatchedByFriends(
  movieId,
  userId
) {
  if (!userId) {
    return [];
  }

  const result =
    await pool.query(
      `
        SELECT

          u.id
            AS user_id,

          u.username,

          u.avatar_url,

          r.rating,

          EXISTS (
            SELECT 1

            FROM diary_entries d

            WHERE
              d.user_id = u.id
              AND d.movie_id = $1
              AND d.is_rewatch = true
          ) AS is_rewatch

        FROM follows f

        JOIN watched_movies w

          ON w.user_id =
             f.following_id

          AND w.movie_id = $1

        JOIN users u

          ON u.id =
             f.following_id

        LEFT JOIN ratings r

          ON r.user_id = u.id

          AND r.movie_id = $1

        WHERE
          f.follower_id = $2

        ORDER BY
          w.watched_at DESC

        LIMIT 8
      `,
      [
        movieId,
        userId,
      ]
    );

  return result.rows;
}

async function getUserMovieState(
  movieId,
  userId
) {
  if (!userId) {
    return {
      watched: false,
      in_watchlist: false,
      liked: false,
      rating: null,
      review: null,
    };
  }

  const result =
    await pool.query(
      `
        SELECT

          EXISTS (
            SELECT 1

            FROM watched_movies

            WHERE
              user_id = $1
              AND movie_id = $2
          ) AS watched,

          EXISTS (
            SELECT 1

            FROM watchlist

            WHERE
              user_id = $1
              AND movie_id = $2
          ) AS in_watchlist,

          EXISTS (
            SELECT 1

            FROM movie_likes

            WHERE
              user_id = $1
              AND movie_id = $2
          ) AS liked,

          (
            SELECT rating

            FROM ratings

            WHERE
              user_id = $1
              AND movie_id = $2
          ) AS rating,

          (
            SELECT
              row_to_json(
                review_row
              )

            FROM (
              SELECT

                rv.id,

                rv.content,

                rv.is_spoiler,

                rv.created_at,

                COALESCE(
                  d.rating,
                  current_rating.rating
                ) AS rating

              FROM reviews rv

              LEFT JOIN diary_entries d

                ON d.id =
                   rv.diary_entry_id

              LEFT JOIN ratings current_rating

                ON current_rating.user_id =
                   rv.user_id

                AND current_rating.movie_id =
                    rv.movie_id

              WHERE
                rv.user_id = $1
                AND rv.movie_id = $2

              ORDER BY
                rv.created_at DESC

              LIMIT 1
            ) AS review_row
          ) AS review
      `,
      [
        userId,
        movieId,
      ]
    );

  return result.rows[0];
}

async function findPageData(
  movieId,
  userId
) {
  const [
    stats,
    ratingsDistribution,
    watchedBy,
    userState,
  ] = await Promise.all([
    getMovieStats(
      movieId
    ),

    getRatingsDistribution(
      movieId
    ),

    getWatchedByFriends(
      movieId,
      userId
    ),

    getUserMovieState(
      movieId,
      userId
    ),
  ]);

  return {
    stats,
    ratingsDistribution,
    watchedBy,
    userState,
  };
}

module.exports = {
  findAll,
  findById,
  search,
  findPageData,
};