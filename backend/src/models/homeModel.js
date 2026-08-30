const pool = require('../config/db');

// "Popular this week" — filmovi koje je NAJVIŠE korisnika obeležilo
// kao pogledano u poslednjih 7 dana. Globalno, ne zavisi od toga
// koga korisnik prati.
async function getPopularThisWeek(limit = 10) {
  const result = await pool.query(
    `SELECT m.id, m.title, m.poster_url,
            COUNT(w.id) AS watch_count
     FROM watched_movies w
     JOIN movies m ON m.id = w.movie_id
     WHERE w.watched_at >= NOW() - INTERVAL '7 days'
     GROUP BY m.id
     ORDER BY watch_count DESC, m.title ASC
     LIMIT $1`,
    [limit]
  );
  return result.rows;
}

// "New from friends" — najnovije OCENE i RECENZIJE (ne watched/watchlist,
// to je za feed) od korisnika koje trenutni korisnik prati. Ako ne prati
// nikoga, prazan niz (bez greške).
async function getNewFromFriends(userId, limit = 20) {
  const result = await pool.query(
    `
    WITH followed AS (
      SELECT following_id AS user_id FROM follows WHERE follower_id = $1
    ),
    activity AS (
      SELECT 'rating' AS type, r.created_at AS occurred_at,
             u.id AS user_id, u.username, u.avatar_url,
             m.id AS movie_id, m.title, m.poster_url,
             r.rating::TEXT AS extra,
             NULL AS is_spoiler
      FROM ratings r
      JOIN followed f ON f.user_id = r.user_id
      JOIN users u ON u.id = r.user_id
      JOIN movies m ON m.id = r.movie_id

      UNION ALL

      SELECT 'review' AS type, rv.created_at AS occurred_at,
             u.id AS user_id, u.username, u.avatar_url,
             m.id AS movie_id, m.title, m.poster_url,
             LEFT(rv.content, 140) AS extra,
             rv.is_spoiler
      FROM reviews rv
      JOIN followed f ON f.user_id = rv.user_id
      JOIN users u ON u.id = rv.user_id
      JOIN movies m ON m.id = rv.movie_id
    )
    SELECT * FROM activity
    ORDER BY occurred_at DESC
    LIMIT $2
    `,
    [userId, limit]
  );
  return result.rows;
}

// "Popular with friends" — filmovi koje je NAJVIŠE ljudi koje pratiš
// gledalo, ikad (ne ograničeno na poslednjih 7 dana, za razliku od
// "Popular this week"). Ako korisnik ne prati nikoga, prazan niz.
async function getPopularWithFriends(userId, limit = 10) {
  const result = await pool.query(
    `SELECT m.id, m.title, m.poster_url,
            COUNT(DISTINCT w.user_id) AS friend_watch_count
     FROM watched_movies w
     JOIN movies m ON m.id = w.movie_id
     WHERE w.user_id IN (SELECT following_id FROM follows WHERE follower_id = $1)
     GROUP BY m.id
     ORDER BY friend_watch_count DESC, m.title ASC
     LIMIT $2`,
    [userId, limit]
  );
  return result.rows;
}

module.exports = {
  getPopularThisWeek,
  getNewFromFriends,
  getPopularWithFriends,
};
