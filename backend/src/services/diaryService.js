const pool = require('../config/db');
const diaryModel = require('../models/diaryModel');

// Kreira diary unos I, ako korisnik već nema watched_movies zapis za
// taj film, dodaje ga (transakciono — oba insert-a uspevaju zajedno
// ili nijedan). Ako watched_movies zapis već postoji (npr. korisnik
// je ranije ručno obeležio film kao gledan, ili ovo je rewatch),
// NE menjamo postojeći watched_at — prvi datum gledanja ostaje
// zapamćen, diary_entries čuva potpunu istoriju (uključujući rewatch-eve).
async function createDiaryEntry({ userId, movieId, watchedDate, isRewatch, note }) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const entry = await diaryModel.createWithClient(client, {
      userId, movieId, watchedDate, isRewatch, note,
    });

    const alreadyWatched = await diaryModel.watchedRecordExists(client, userId, movieId);
    if (!alreadyWatched) {
      // watched_at dobija watchedDate ako je prosleđen (kao timestamp
      // tog dana), inače trenutni momenat.
      const watchedAt = watchedDate ? `${watchedDate} 00:00:00` : null;
      await diaryModel.insertWatchedRecord(client, userId, movieId, watchedAt);
    }

    await client.query('COMMIT');
    return entry;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

module.exports = {
  createDiaryEntry,
};
