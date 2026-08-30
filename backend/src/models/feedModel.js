const pool = require('../config/db');

// Aktivnost se generiše iz 4 izvora (rating, review, watched, watchlist),
// spojenih preko UNION ALL i sortiranih po vremenu. Svaki tip aktivnosti
// nosi svoje polje ("extra") za dodatni kontekst (npr. rating vrednost
// ili početak recenzije).
async function getFeedForUser(userId, { limit = 20, offset = 0 }) {
  const result = await pool.query(
    `
    WITH followed AS (
      SELECT following_id AS user_id FROM follows WHERE follower_id = $1
    ),
    activities AS (
      SELECT 'rating' AS type, r.created_at AS occurred_at,
             u.id AS user_id, u.username, u.avatar_url,
             m.id AS movie_id, m.title, m.poster_url,
             r.rating::TEXT AS extra
      FROM ratings r
      JOIN followed f ON f.user_id = r.user_id
      JOIN users u ON u.id = r.user_id
      JOIN movies m ON m.id = r.movie_id

      UNION ALL

      SELECT 'review' AS type, rv.created_at AS occurred_at,
             u.id AS user_id, u.username, u.avatar_url,
             m.id AS movie_id, m.title, m.poster_url,
             LEFT(rv.content, 140) AS extra
      FROM reviews rv
      JOIN followed f ON f.user_id = rv.user_id
      JOIN users u ON u.id = rv.user_id
      JOIN movies m ON m.id = rv.movie_id

      UNION ALL

      SELECT 'watched' AS type, w.watched_at AS occurred_at,
             u.id AS user_id, u.username, u.avatar_url,
             m.id AS movie_id, m.title, m.poster_url,
             NULL AS extra
      FROM watched_movies w
      JOIN followed f ON f.user_id = w.user_id
      JOIN users u ON u.id = w.user_id
      JOIN movies m ON m.id = w.movie_id

      UNION ALL

      SELECT 'watchlist' AS type, wl.created_at AS occurred_at,
             u.id AS user_id, u.username, u.avatar_url,
             m.id AS movie_id, m.title, m.poster_url,
             NULL AS extra
      FROM watchlist wl
      JOIN followed f ON f.user_id = wl.user_id
      JOIN users u ON u.id = wl.user_id
      JOIN movies m ON m.id = wl.movie_id
    )
    SELECT * FROM activities
    ORDER BY occurred_at DESC
    LIMIT $2 OFFSET $3
    `,
    [userId, limit, offset]
  );
  return result.rows;
}

module.exports = {
  getFeedForUser,
};
