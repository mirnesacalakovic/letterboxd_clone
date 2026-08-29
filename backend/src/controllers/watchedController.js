const watchedModel = require('../models/watchedModel');

// POST /api/watched/:movieId — označava film kao pogledan.
// Idempotentno-ish: ako je već obeležen, vraća 409 (isto ponašanje kao
// kod ratings — jasno korisniku da je akcija već izvršena).
async function markAsWatched(req, res) {
  try {
    const { movieId } = req.params;

    const existing = await watchedModel.findByUserAndMovie(req.userId, movieId);
    if (existing) {
      return res.status(409).json({ error: 'Film je već obeležen kao pogledan' });
    }

    const watched = await watchedModel.markAsWatched(req.userId, movieId);
    res.status(201).json({ watched });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// DELETE /api/watched/:movieId — uklanja watched status.
async function removeWatched(req, res) {
  try {
    const { movieId } = req.params;

    const existing = await watchedModel.findByUserAndMovie(req.userId, movieId);
    if (!existing) {
      return res.status(404).json({ error: 'Film nije obeležen kao pogledan' });
    }

    await watchedModel.removeWatched(req.userId, movieId);
    res.json({ message: 'Watched status uklonjen' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// GET /api/watched — svi pogledani filmovi TRENUTNO ulogovanog korisnika.
async function getAllForUser(req, res) {
  try {
    const watched = await watchedModel.findAllForUser(req.userId);
    res.json({ watched });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

module.exports = {
  markAsWatched,
  removeWatched,
  getAllForUser,
};