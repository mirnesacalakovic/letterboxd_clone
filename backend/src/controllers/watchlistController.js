const watchlistModel = require('../models/watchlistModel');

// POST /api/watchlist/:movieId
async function addToWatchlist(req, res) {
  try {
    const { movieId } = req.params;

    const existing = await watchlistModel.findByUserAndMovie(req.userId, movieId);
    if (existing) {
      return res.status(409).json({ error: 'Film je već na watchlisti' });
    }

    const entry = await watchlistModel.addToWatchlist(req.userId, movieId);
    res.status(201).json({ watchlist: entry });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// DELETE /api/watchlist/:movieId
async function removeFromWatchlist(req, res) {
  try {
    const { movieId } = req.params;

    const existing = await watchlistModel.findByUserAndMovie(req.userId, movieId);
    if (!existing) {
      return res.status(404).json({ error: 'Film nije na watchlisti' });
    }

    await watchlistModel.removeFromWatchlist(req.userId, movieId);
    res.json({ message: 'Film uklonjen sa watchliste' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// GET /api/watchlist — watchlist trenutno ulogovanog korisnika.
async function getAllForUser(req, res) {
  try {
    const watchlist = await watchlistModel.findAllForUser(req.userId);
    res.json({ watchlist });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

module.exports = {
  addToWatchlist,
  removeFromWatchlist,
  getAllForUser,
};