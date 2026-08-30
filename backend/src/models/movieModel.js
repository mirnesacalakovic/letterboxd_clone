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

// Lista filmova sa paginacijom i opcionim filterima/sortiranjem.
// decade: npr. 1990 → filtrira release_year IZMEĐU 1990 i 1999.
// minRating: filtrira filmove sa average_rating >= data vrednost
//   (primenjuje se u HAVING, jer average_rating je agregatna kolona).
// sortBy: 'newest' (release_year DESC), 'rating' (average_rating DESC),
//   'title' (podrazumevano, alfabetski).
async function findAll({ limit = 20, offset = 0, decade, minRating, sortBy = 'title' }) {
  const conditions = [];
  const params = [];
  let paramIndex = 1;

  if (decade) {
    conditions.push(`m.release_year BETWEEN $${paramIndex} AND $${paramIndex + 1}`);
    params.push(decade, decade + 9);
    paramIndex += 2;
  }

  const whereClause = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const havingConditions = [];
  if (minRating !== undefined) {
    havingConditions.push(`AVG(r.rating) >= $${paramIndex}`);
    params.push(minRating);
    paramIndex += 1;
  }
  const havingClause = havingConditions.length ? `HAVING ${havingConditions.join(' AND ')}` : '';

  const sortColumn = {
    newest: 'm.release_year DESC NULLS LAST',
    rating: 'average_rating DESC NULLS LAST',
    popular: 'rating_count DESC',
    title: 'm.title ASC',
  }[sortBy] || 'm.title ASC';

  params.push(limit, offset);
  const limitParam = paramIndex;
  const offsetParam = paramIndex + 1;

  const result = await pool.query(
    `${BASE_SELECT}
     ${whereClause}
     GROUP BY m.id
     ${havingClause}
     ORDER BY ${sortColumn}
     LIMIT $${limitParam} OFFSET $${offsetParam}`,
    params
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