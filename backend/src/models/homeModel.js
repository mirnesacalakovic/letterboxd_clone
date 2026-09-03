const pool = require('../config/db');

// Popular this week prioritizes watches from the last seven days, but also
// falls back to all-time activity so a fresh/local development database never
// renders an empty first section simply because the seed is older than a week.
async function getPopularThisWeek(limit = 10) {
  const result = await pool.query(
    `SELECT
       m.id,
       m.title,
       m.release_year,
       m.poster_url,
       COUNT(DISTINCT w.id) FILTER (
         WHERE w.watched_at >= NOW() - INTERVAL '7 days'
       ) AS watch_count,
       COUNT(DISTINCT w.id) AS all_time_watch_count,
       ROUND(AVG(r.rating), 2) AS average_rating
     FROM movies m
     LEFT JOIN watched_movies w ON w.movie_id = m.id
     LEFT JOIN ratings r ON r.movie_id = m.id
     GROUP BY m.id
     HAVING COUNT(w.id) > 0
     ORDER BY
       watch_count DESC,
       all_time_watch_count DESC,
       average_rating DESC NULLS LAST,
       m.title ASC
     LIMIT $1`,
    [limit]
  );

  return result.rows;
}

// Latest unique friend/movie activity for the Home poster strip. Rating and
// review actions for the same friend/movie are collapsed into the newest one,
// which prevents duplicate posters appearing next to each other.
async function getNewFromFriends(userId, limit = 20) {
  const result = await pool.query(
    `WITH followed AS (
       SELECT following_id AS user_id
       FROM follows
       WHERE follower_id = $1
     ),
     activity AS (
       SELECT
         'rating'::TEXT AS type,
         COALESCE(r.updated_at, r.created_at) AS occurred_at,
         u.id AS user_id,
         u.username,
         u.avatar_url,
         m.id AS movie_id,
         m.title,
         m.release_year,
         m.poster_url,
         r.rating,
         NULL::TEXT AS review_text,
         NULL::BOOLEAN AS is_spoiler
       FROM ratings r
       JOIN followed f ON f.user_id = r.user_id
       JOIN users u ON u.id = r.user_id
       JOIN movies m ON m.id = r.movie_id

       UNION ALL

       SELECT
         'review'::TEXT AS type,
         rv.created_at AS occurred_at,
         u.id AS user_id,
         u.username,
         u.avatar_url,
         m.id AS movie_id,
         m.title,
         m.release_year,
         m.poster_url,
         COALESCE(d.rating, current_rating.rating) AS rating,
         LEFT(rv.content, 140) AS review_text,
         rv.is_spoiler
       FROM reviews rv
       JOIN followed f ON f.user_id = rv.user_id
       JOIN users u ON u.id = rv.user_id
       JOIN movies m ON m.id = rv.movie_id
       LEFT JOIN diary_entries d ON d.id = rv.diary_entry_id
       LEFT JOIN ratings current_rating
         ON current_rating.user_id = rv.user_id
        AND current_rating.movie_id = rv.movie_id
     ),
     unique_activity AS (
       SELECT DISTINCT ON (user_id, movie_id) *
       FROM activity
       ORDER BY user_id, movie_id, occurred_at DESC
     )
     SELECT *
     FROM unique_activity
     ORDER BY occurred_at DESC
     LIMIT $2`,
    [userId, limit]
  );

  return result.rows;
}

async function getPopularWithFriends(userId, limit = 10) {
  const result = await pool.query(
    `SELECT
       m.id,
       m.title,
       m.release_year,
       m.poster_url,
       COUNT(DISTINCT w.user_id) AS friend_watch_count,
       ROUND(AVG(r.rating), 2) AS average_rating
     FROM watched_movies w
     JOIN movies m ON m.id = w.movie_id
     LEFT JOIN ratings r
       ON r.movie_id = w.movie_id
      AND r.user_id = w.user_id
     WHERE w.user_id IN (
       SELECT following_id
       FROM follows
       WHERE follower_id = $1
     )
     GROUP BY m.id
     ORDER BY
       friend_watch_count DESC,
       average_rating DESC NULLS LAST,
       m.title ASC
     LIMIT $2`,
    [userId, limit]
  );

  return result.rows;
}

async function getPopularReviews(limit = 20) {
  const result = await pool.query(
    `SELECT
       rv.id,
       rv.user_id,
       u.username,
       u.avatar_url,
       rv.movie_id,
       m.title,
       m.release_year,
       m.poster_url,
       rv.content,
       rv.is_spoiler,
       rv.created_at,
       COALESCE(d.rating, current_rating.rating) AS rating,
       COUNT(DISTINCT rl.id) AS like_count,
       COUNT(DISTINCT rc.id) AS comment_count
     FROM reviews rv
     JOIN users u ON u.id = rv.user_id
     JOIN movies m ON m.id = rv.movie_id
     LEFT JOIN diary_entries d ON d.id = rv.diary_entry_id
     LEFT JOIN ratings current_rating
       ON current_rating.user_id = rv.user_id
      AND current_rating.movie_id = rv.movie_id
     LEFT JOIN review_likes rl ON rl.review_id = rv.id
     LEFT JOIN review_comments rc ON rc.review_id = rv.id
     GROUP BY
       rv.id,
       u.id,
       m.id,
       d.rating,
       current_rating.rating
     ORDER BY
       like_count DESC,
       comment_count DESC,
       rv.created_at DESC
     LIMIT $1`,
    [limit]
  );

  return result.rows;
}

async function getPopularLists(limit = 20) {
  const result = await pool.query(
    `SELECT
       l.id,
       l.name,
       l.description,
       l.created_at,
       u.id AS user_id,
       u.username,
       u.avatar_url,
       COUNT(lm.movie_id) AS movie_count,
       ARRAY(
         SELECT m2.poster_url
         FROM list_movies preview
         JOIN movies m2 ON m2.id = preview.movie_id
         WHERE preview.list_id = l.id
           AND m2.poster_url IS NOT NULL
         ORDER BY preview.position ASC
         LIMIT 4
       ) AS poster_urls
     FROM movie_lists l
     JOIN users u ON u.id = l.user_id
     LEFT JOIN list_movies lm ON lm.list_id = l.id
     WHERE l.is_public = true
     GROUP BY l.id, u.id
     ORDER BY
       movie_count DESC,
       l.created_at DESC
     LIMIT $1`,
    [limit]
  );

  return result.rows;
}

module.exports = {
  getPopularThisWeek,
  getNewFromFriends,
  getPopularWithFriends,
  getPopularReviews,
  getPopularLists,
};