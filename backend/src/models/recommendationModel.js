const pool = require('../config/db');

// Ukupan broj ocena korisnika — koristi se za cold start proveru
// (potrebno je bar 5 ocena da bi profil bio pouzdan, po specifikaciji).
async function getUserRatingCount(userId) {
  const result = await pool.query(
    'SELECT COUNT(*) AS count FROM ratings WHERE user_id = $1',
    [userId]
  );
  return parseInt(result.rows[0].count, 10);
}

// Zajednička agregacija žanrova, koristi se u više upita ispod.
const GENRE_AGG = `
  COALESCE(array_agg(DISTINCT g.name) FILTER (WHERE g.name IS NOT NULL), '{}') AS genres
`;

// Filmovi koje je korisnik ocenio sa 4.0 ili više, sa svim feature
// podacima potrebnim za vektor (žanrovi, režiser, glumci, keywords).
// Ovo je osnova za user preference profile (tačka 11.2 specifikacije).
async function getUserHighRatedMoviesWithFeatures(userId) {
  const result = await pool.query(
    `SELECT m.id, m.title, m.director, m.actors, m.keywords, r.rating,
            ${GENRE_AGG}
     FROM ratings r
     JOIN movies m ON m.id = r.movie_id
     LEFT JOIN movie_genres mg ON mg.movie_id = m.id
     LEFT JOIN genres g ON g.id = mg.genre_id
     WHERE r.user_id = $1 AND r.rating >= 4.0
     GROUP BY m.id, r.rating`,
    [userId]
  );
  return result.rows;
}

// Svi filmovi koje korisnik NIJE gledao i NIJE ocenio — kandidati za
// preporuku (tačka 11.4 — filtriranje već poznatih filmova).
async function getCandidateMoviesWithFeatures(userId) {
  const result = await pool.query(
    `SELECT m.id, m.title, m.poster_url, m.director, m.actors, m.keywords,
            ${GENRE_AGG}
     FROM movies m
     LEFT JOIN movie_genres mg ON mg.movie_id = m.id
     LEFT JOIN genres g ON g.id = mg.genre_id
     WHERE m.id NOT IN (SELECT movie_id FROM ratings WHERE user_id = $1)
       AND m.id NOT IN (SELECT movie_id FROM watched_movies WHERE user_id = $1)
       AND m.id NOT IN (SELECT movie_id FROM watchlist WHERE user_id = $1)
     GROUP BY m.id`,
    [userId]
  );
  return result.rows;
}

// Popularni filmovi za cold start — najviša prosečna ocena, uz minimum
// broja ocena da rezultat ne bude slučajan (jedan film sa jednom
// ocenom 5.0 ne treba da bude "najpopularniji").
async function getPopularMovies(limit) {
  const result = await pool.query(
    `SELECT m.id, m.title, m.poster_url, m.director,
            ${GENRE_AGG},
            ROUND(AVG(r.rating), 2) AS average_rating,
            COUNT(r.id) AS rating_count
     FROM movies m
     LEFT JOIN movie_genres mg ON mg.movie_id = m.id
     LEFT JOIN genres g ON g.id = mg.genre_id
     JOIN ratings r ON r.movie_id = m.id
     GROUP BY m.id
     HAVING COUNT(r.id) >= 3
     ORDER BY average_rating DESC, rating_count DESC
     LIMIT $1`,
    [limit]
  );
  return result.rows;
}

module.exports = {
  getUserRatingCount,
  getUserHighRatedMoviesWithFeatures,
  getCandidateMoviesWithFeatures,
  getPopularMovies,
};
