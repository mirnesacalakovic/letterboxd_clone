const pool = require('../config/db');

// Top 4 omiljena filma korisnika, sortirano po poziciji — koristi se
// za prikaz na profilu.
async function findForUser(userId) {
  const result = await pool.query(
    `SELECT f.position, m.id AS movie_id, m.title, m.release_year, m.poster_url
     FROM user_favorite_movies f
     JOIN movies m ON m.id = f.movie_id
     WHERE f.user_id = $1
     ORDER BY f.position ASC`,
    [userId]
  );
  return result.rows;
}

// Zamenjuje CEO set omiljenih filmova korisnika (max 4, ID redosled =
// pozicija). Transakciono — briše stare, upisuje nove, jer je lakše
// nego selektivno računati diff-ove za samo 4 stavke.
async function setForUser(userId, movieIds) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query('DELETE FROM user_favorite_movies WHERE user_id = $1', [userId]);

    for (let i = 0; i < movieIds.length; i++) {
      await client.query(
        `INSERT INTO user_favorite_movies (user_id, movie_id, position)
         VALUES ($1, $2, $3)`,
        [userId, movieIds[i], i + 1]
      );
    }

    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
  return findForUser(userId);
}

module.exports = {
  findForUser,
  setForUser,
};
