const pool = require('../config/db');

// Ako je year prosleđen, filtrira watched_movies/ratings na tu godinu
// (po watched_at / created_at). Ako nije, računa STATISTIKU ZA SVA VREMENA.
async function getUserStats(userId, year) {
  const yearFilter = year ? 'AND EXTRACT(YEAR FROM w.watched_at) = $2' : '';
  const yearFilterRatings = year ? 'AND EXTRACT(YEAR FROM r.created_at) = $2' : '';
  const params = year ? [userId, year] : [userId];

  // Osnovni brojevi: ukupno gledano, ukupno vreme (runtime), prosečna ocena.
  const summaryResult = await pool.query(
    `SELECT
       COUNT(DISTINCT w.id) AS movies_watched,
       COALESCE(SUM(m.runtime), 0) AS total_runtime_minutes,
       (SELECT ROUND(AVG(r.rating), 2)
        FROM ratings r
        WHERE r.user_id = $1 ${yearFilterRatings}) AS average_rating
     FROM watched_movies w
     JOIN movies m ON m.id = w.movie_id
     WHERE w.user_id = $1 ${yearFilter}`,
    params
  );

  // Najgledaniji žanr (po broju pogledanih filmova tog žanra).
  const topGenreResult = await pool.query(
    `SELECT g.name, COUNT(*) AS count
     FROM watched_movies w
     JOIN movies m ON m.id = w.movie_id
     JOIN movie_genres mg ON mg.movie_id = m.id
     JOIN genres g ON g.id = mg.genre_id
     WHERE w.user_id = $1 ${yearFilter}
     GROUP BY g.name
     ORDER BY count DESC
     LIMIT 5`,
    params
  );

  // Najgledaniji režiser.
  const topDirectorResult = await pool.query(
    `SELECT m.director, COUNT(*) AS count
     FROM watched_movies w
     JOIN movies m ON m.id = w.movie_id
     WHERE w.user_id = $1 ${yearFilter} AND m.director IS NOT NULL
     GROUP BY m.director
     ORDER BY count DESC
     LIMIT 5`,
    params
  );

  // Mesečna raspodela (koliko filmova po mesecu) — samo ima smisla
  // kad je year prosleđen, inače bi mešala mesece iz različitih godina.
  let monthlyBreakdown = null;
  if (year) {
    const monthlyResult = await pool.query(
      `SELECT EXTRACT(MONTH FROM w.watched_at) AS month, COUNT(*) AS count
       FROM watched_movies w
       WHERE w.user_id = $1 AND EXTRACT(YEAR FROM w.watched_at) = $2
       GROUP BY month
       ORDER BY month ASC`,
      [userId, year]
    );
    monthlyBreakdown = monthlyResult.rows;
  }

  return {
    summary: summaryResult.rows[0],
    topGenres: topGenreResult.rows,
    topDirectors: topDirectorResult.rows,
    monthlyBreakdown,
  };
}

module.exports = {
  getUserStats,
};
