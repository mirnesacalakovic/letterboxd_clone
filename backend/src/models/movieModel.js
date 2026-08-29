const pool = require('../config/db');

// Zajednički SELECT sa agregiranim žanrovima i prosečnom ocenom,
// da ne dupliramo ovaj upit u svakoj funkciji ispod.
const BASE_SELECT = `
  SELECT
    m.id, m.title, m.release_year, m.director, m.overview, m.runtime,
    m.actors, m.keywords, m.poster_url, m.backdrop_url,
    COALESCE(array_agg(DISTINCT g.name) FILTER (WHERE g.name IS NOT NULL), '{}') AS genres,
    ROUND(AVG(r.rating), 2) AS average_rating,
    COUNT(DISTINCT r.id) AS rating_count
  FROM movies m
  LEFT JOIN movie_genres mg ON mg.movie_id = m.id
  LEFT JOIN genres g ON g.id = mg.genre_id
  LEFT JOIN ratings r ON r.movie_id = m.id
`;

// Lista filmova sa paginacijom, sortirano po naslovu.
async function findAll({ limit = 20, offset = 0 }) {
  const result = await pool.query(
    `${BASE_SELECT}
     GROUP BY m.id
     ORDER BY m.title ASC
     LIMIT $1 OFFSET $2`,
    [limit, offset]
  );
  return result.rows;
}

// Detalji jednog filma po id-u.
async function findById(id) {
  const result = await pool.query(
    `${BASE_SELECT}
     WHERE m.id = $1
     GROUP BY m.id`,
    [id]
  );
  return result.rows[0] || null;
}

// Pretraga po nazivu (ILIKE, case-insensitive) ILI po režiseru/glumcima/žanru.
// Koristi se za GET /api/movies/search?q=...
async function search(query, { limit = 20, offset = 0 }) {
  const likeQuery = `%${query}%`;
  const result = await pool.query(
    `${BASE_SELECT}
     WHERE m.title ILIKE $1
        OR m.director ILIKE $1
        OR EXISTS (
          SELECT 1 FROM unnest(m.actors) AS actor WHERE actor ILIKE $1
        )
        OR EXISTS (
          SELECT 1 FROM movie_genres mg2
          JOIN genres g2 ON g2.id = mg2.genre_id
          WHERE mg2.movie_id = m.id AND g2.name ILIKE $1
        )
     GROUP BY m.id
     ORDER BY m.title ASC
     LIMIT $2 OFFSET $3`,
    [likeQuery, limit, offset]
  );
  return result.rows;
}

module.exports = {
  findAll,
  findById,
  search,
};