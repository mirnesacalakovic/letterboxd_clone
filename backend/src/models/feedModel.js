const pool = require('../config/db');

const FEED_SELECT = `
  SELECT *
  FROM activities
  ORDER BY occurred_at DESC
  LIMIT $2 OFFSET $3
`;

function actorScope(mode) {
  if (mode === 'you') {
    return 'SELECT $1::BIGINT AS user_id';
  }

  return `
    SELECT following_id AS user_id
    FROM follows
    WHERE follower_id = $1
  `;
}

async function getActivityFeed(
  userId,
  {
    mode = 'friends',
    limit = 50,
    offset = 0,
  } = {}
) {
  const scope = actorScope(mode);

  const result = await pool.query(
    `
    WITH actors AS (
      ${scope}
    ),
    activities AS (

      -- ==========================================
      -- REVIEWS
      -- ==========================================

      SELECT
        'review'::TEXT AS type,
        rv.id::TEXT AS source_id,
        rv.created_at AS occurred_at,

        u.id AS user_id,
        u.username,
        u.avatar_url,

        m.id AS movie_id,
        m.title,
        m.release_year,
        m.poster_url,

        COALESCE(
          d.rating,
          r.rating
        ) AS rating,

        LEFT(
          rv.content,
          280
        ) AS extra,

        rv.is_spoiler,
        rv.id AS review_id

      FROM reviews rv

      JOIN actors a
        ON a.user_id = rv.user_id

      JOIN users u
        ON u.id = rv.user_id

      JOIN movies m
        ON m.id = rv.movie_id

      LEFT JOIN diary_entries d
        ON d.id = rv.diary_entry_id

      LEFT JOIN ratings r
        ON r.user_id = rv.user_id
       AND r.movie_id = rv.movie_id


      UNION ALL


      -- ==========================================
      -- DIARY / WATCHED
      --
      -- Ako diary entry ima review, ne prikazujemo
      -- poseban "watched" event jer bi ista akcija
      -- bila duplirana kao review + watched.
      -- ==========================================

      SELECT
        'watched'::TEXT AS type,
        d.id::TEXT AS source_id,
        d.created_at AS occurred_at,

        u.id AS user_id,
        u.username,
        u.avatar_url,

        m.id AS movie_id,
        m.title,
        m.release_year,
        m.poster_url,

        d.rating AS rating,

        NULLIF(
          LEFT(
            d.note,
            280
          ),
          ''
        ) AS extra,

        NULL::BOOLEAN AS is_spoiler,
        NULL::BIGINT AS review_id

      FROM diary_entries d

      JOIN actors a
        ON a.user_id = d.user_id

      JOIN users u
        ON u.id = d.user_id

      JOIN movies m
        ON m.id = d.movie_id

      WHERE NOT EXISTS (
        SELECT 1
        FROM reviews rv
        WHERE rv.diary_entry_id = d.id
      )


      UNION ALL


      -- ==========================================
      -- RATING VAN DIARY FLOW-A
      --
      -- Ako je rating došao kroz Log/Diary,
      -- diary event ga već prikazuje.
      -- ==========================================

      SELECT
        'rating'::TEXT AS type,
        r.id::TEXT AS source_id,

        COALESCE(
          r.updated_at,
          r.created_at
        ) AS occurred_at,

        u.id AS user_id,
        u.username,
        u.avatar_url,

        m.id AS movie_id,
        m.title,
        m.release_year,
        m.poster_url,

        r.rating AS rating,

        NULL::TEXT AS extra,
        NULL::BOOLEAN AS is_spoiler,
        NULL::BIGINT AS review_id

      FROM ratings r

      JOIN actors a
        ON a.user_id = r.user_id

      JOIN users u
        ON u.id = r.user_id

      JOIN movies m
        ON m.id = r.movie_id

      WHERE NOT EXISTS (
        SELECT 1

        FROM diary_entries d

        WHERE d.user_id = r.user_id
          AND d.movie_id = r.movie_id
      )


      UNION ALL


      -- ==========================================
      -- STARI WATCHED PODACI
      --
      -- Potrebno zbog postojećeg seeda.
      -- Novi Log flow pravi diary entry, pa se
      -- ti unosi gore već hvataju.
      -- ==========================================

      SELECT
        'watched'::TEXT AS type,
        w.id::TEXT AS source_id,
        w.watched_at AS occurred_at,

        u.id AS user_id,
        u.username,
        u.avatar_url,

        m.id AS movie_id,
        m.title,
        m.release_year,
        m.poster_url,

        r.rating AS rating,

        NULL::TEXT AS extra,
        NULL::BOOLEAN AS is_spoiler,
        NULL::BIGINT AS review_id

      FROM watched_movies w

      JOIN actors a
        ON a.user_id = w.user_id

      JOIN users u
        ON u.id = w.user_id

      JOIN movies m
        ON m.id = w.movie_id

      LEFT JOIN ratings r
        ON r.user_id = w.user_id
       AND r.movie_id = w.movie_id

      WHERE NOT EXISTS (
        SELECT 1

        FROM diary_entries d

        WHERE d.user_id = w.user_id
          AND d.movie_id = w.movie_id
      )


      UNION ALL


      -- ==========================================
      -- WATCHLIST
      -- ==========================================

      SELECT
        'watchlist'::TEXT AS type,
        wl.id::TEXT AS source_id,
        wl.created_at AS occurred_at,

        u.id AS user_id,
        u.username,
        u.avatar_url,

        m.id AS movie_id,
        m.title,
        m.release_year,
        m.poster_url,

        NULL::NUMERIC AS rating,
        NULL::TEXT AS extra,
        NULL::BOOLEAN AS is_spoiler,
        NULL::BIGINT AS review_id

      FROM watchlist wl

      JOIN actors a
        ON a.user_id = wl.user_id

      JOIN users u
        ON u.id = wl.user_id

      JOIN movies m
        ON m.id = wl.movie_id
    )

    ${FEED_SELECT}
    `,
    [
      userId,
      limit,
      offset,
    ]
  );

  return result.rows;
}


// ============================================================
// INCOMING
//
// Stvari koje drugi korisnici rade TEBI:
// - like na tvoju recenziju
// - komentar na tvoju recenziju
// - novi follower
// ============================================================

async function getIncomingFeed(
  userId,
  {
    limit = 50,
    offset = 0,
  } = {}
) {
  const result = await pool.query(
    `
    WITH activities AS (

      -- ==========================================
      -- REVIEW LIKE
      -- ==========================================

      SELECT
        'review_like'::TEXT AS type,
        rl.id::TEXT AS source_id,
        rl.created_at AS occurred_at,

        actor.id AS user_id,
        actor.username,
        actor.avatar_url,

        m.id AS movie_id,
        m.title,
        m.release_year,
        m.poster_url,

        COALESCE(
          d.rating,
          owner_rating.rating
        ) AS rating,

        LEFT(
          rv.content,
          280
        ) AS extra,

        rv.is_spoiler,
        rv.id AS review_id

      FROM review_likes rl

      JOIN reviews rv
        ON rv.id = rl.review_id

      JOIN users actor
        ON actor.id = rl.user_id

      JOIN movies m
        ON m.id = rv.movie_id

      LEFT JOIN diary_entries d
        ON d.id = rv.diary_entry_id

      LEFT JOIN ratings owner_rating
        ON owner_rating.user_id = rv.user_id
       AND owner_rating.movie_id = rv.movie_id

      WHERE rv.user_id = $1
        AND rl.user_id <> $1


      UNION ALL


      -- ==========================================
      -- COMMENT / REPLY
      -- ==========================================

      SELECT
        'comment'::TEXT AS type,
        rc.id::TEXT AS source_id,
        rc.created_at AS occurred_at,

        actor.id AS user_id,
        actor.username,
        actor.avatar_url,

        m.id AS movie_id,
        m.title,
        m.release_year,
        m.poster_url,

        COALESCE(
          d.rating,
          owner_rating.rating
        ) AS rating,

        LEFT(
          rc.content,
          280
        ) AS extra,

        rv.is_spoiler,
        rv.id AS review_id

      FROM review_comments rc

      JOIN reviews rv
        ON rv.id = rc.review_id

      JOIN users actor
        ON actor.id = rc.user_id

      JOIN movies m
        ON m.id = rv.movie_id

      LEFT JOIN diary_entries d
        ON d.id = rv.diary_entry_id

      LEFT JOIN ratings owner_rating
        ON owner_rating.user_id = rv.user_id
       AND owner_rating.movie_id = rv.movie_id

      WHERE rv.user_id = $1
        AND rc.user_id <> $1


      UNION ALL


      -- ==========================================
      -- FOLLOW
      -- ==========================================

      SELECT
        'follow'::TEXT AS type,
        f.id::TEXT AS source_id,
        f.created_at AS occurred_at,

        actor.id AS user_id,
        actor.username,
        actor.avatar_url,

        NULL::BIGINT AS movie_id,
        NULL::TEXT AS title,
        NULL::INTEGER AS release_year,
        NULL::TEXT AS poster_url,

        NULL::NUMERIC AS rating,
        NULL::TEXT AS extra,
        NULL::BOOLEAN AS is_spoiler,
        NULL::BIGINT AS review_id

      FROM follows f

      JOIN users actor
        ON actor.id = f.follower_id

      WHERE f.following_id = $1
        AND f.follower_id <> $1
    )

    ${FEED_SELECT}
    `,
    [
      userId,
      limit,
      offset,
    ]
  );

  return result.rows;
}

module.exports = {
  getActivityFeed,
  getIncomingFeed,
};