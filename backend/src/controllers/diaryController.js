const diaryModel = require('../models/diaryModel');
const diaryService = require('../services/diaryService');

const MAX_NOTE_LENGTH = 1000;

// Validira datum u formatu YYYY-MM-DD i da nije u budućnosti (ne može
// se "gledati" film sutra).
function isValidWatchedDate(dateStr) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) return false;
  const date = new Date(dateStr);
  if (isNaN(date.getTime())) return false;
  return date <= new Date();
}

// POST /api/diary
async function create(req, res) {
  try {
    const { movieId, watchedDate, isRewatch, note } = req.body;

    if (!movieId) {
      return res.status(400).json({ error: 'movieId je obavezan' });
    }
    if (watchedDate !== undefined && !isValidWatchedDate(watchedDate)) {
      return res.status(400).json({ error: 'watchedDate mora biti validan datum (YYYY-MM-DD) koji nije u budućnosti' });
    }
    if (note !== undefined && note.length > MAX_NOTE_LENGTH) {
      return res.status(400).json({ error: `note ne sme biti duži od ${MAX_NOTE_LENGTH} karaktera` });
    }

    const entry = await diaryService.createDiaryEntry({
      userId: req.userId,
      movieId,
      watchedDate,
      isRewatch: !!isRewatch,
      note,
    });
    res.status(201).json({ entry });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// GET /api/diary — dnevnik TRENUTNO ulogovanog korisnika.
async function getOwnDiary(req, res) {
  try {
    const limit = parseInt(req.query.limit, 10) || 20;
    const offset = parseInt(req.query.offset, 10) || 0;
    const entries = await diaryModel.findAllForUser(req.userId, { limit, offset });
    res.json({ entries });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// GET /api/users/:id/diary — javni dnevnik nekog drugog korisnika.
async function getDiaryForUser(req, res) {
  try {
    const limit = parseInt(req.query.limit, 10) || 20;
    const offset = parseInt(req.query.offset, 10) || 0;
    const entries = await diaryModel.findAllForUser(req.params.id, { limit, offset });
    res.json({ entries });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// PUT /api/diary/:id — samo vlasnik.
async function update(req, res) {
  try {
    const { watchedDate, isRewatch, note } = req.body;

    if (watchedDate !== undefined && !isValidWatchedDate(watchedDate)) {
      return res.status(400).json({ error: 'watchedDate mora biti validan datum (YYYY-MM-DD) koji nije u budućnosti' });
    }
    if (note !== undefined && note.length > MAX_NOTE_LENGTH) {
      return res.status(400).json({ error: `note ne sme biti duži od ${MAX_NOTE_LENGTH} karaktera` });
    }

    const existing = await diaryModel.findById(req.params.id);
    if (!existing) {
      return res.status(404).json({ error: 'Diary unos ne postoji' });
    }
    if (existing.user_id !== req.userId) {
      return res.status(403).json({ error: 'Nemaš pravo da menjaš tuđ diary unos' });
    }

    const updated = await diaryModel.update(req.params.id, { watchedDate, isRewatch, note });
    res.json({ entry: updated });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// DELETE /api/diary/:id — samo vlasnik. NAPOMENA: brisanje diary unosa
// NE menja watched_movies status — namerno odvojeno (videti komentar
// u diaryService.js), da ponašanje ostane jednostavno i predvidivo.
async function remove(req, res) {
  try {
    const existing = await diaryModel.findById(req.params.id);
    if (!existing) {
      return res.status(404).json({ error: 'Diary unos ne postoji' });
    }
    if (existing.user_id !== req.userId) {
      return res.status(403).json({ error: 'Nemaš pravo da brišeš tuđ diary unos' });
    }

    await diaryModel.remove(req.params.id);
    res.json({ message: 'Diary unos obrisan' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

module.exports = {
  create,
  getOwnDiary,
  getDiaryForUser,
  update,
  remove,
};
