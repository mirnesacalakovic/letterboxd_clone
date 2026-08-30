const pool = require('../config/db');
const reviewModel = require('../models/reviewModel');
const ratingModel = require('../models/ratingModel');

// Kombinovani unos: recenzija + ocena u JEDNOM pozivu (kako pravi
// Letterboxd radi — jedan formular za oboje). Koristi DB transakciju
// jer se piše u DVE tabele (reviews i ratings) — ako drugi insert
// pukne (npr. korisnik već ima ocenu za taj film), PRVI se mora
// poništiti (ROLLBACK), inače bi ostala recenzija bez ocene iako je
// ceo poziv trebalo da bude "sve ili ništa".
async function createReviewWithRating({ userId, movieId, content, isSpoiler, tags, rating }) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const review = await reviewModel.createWithClient(client, { userId, movieId, content, isSpoiler, tags });

    let createdRating = null;
    if (rating !== undefined) {
      const result = await client.query(
        `INSERT INTO ratings (user_id, movie_id, rating)
         VALUES ($1, $2, $3)
         RETURNING *`,
        [userId, movieId, rating]
      );
      createdRating = result.rows[0];
    }

    await client.query('COMMIT');
    return { review, rating: createdRating };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

module.exports = {
  createReviewWithRating,
};