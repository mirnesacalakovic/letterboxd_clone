const userModel = require('../models/userModel');
const favoriteModel = require('../models/favoriteModel');

const MAX_FAVORITES = 4;

// GET /api/users/:id — javni profil, svako može da vidi.
// Uključuje top 4 omiljena filma (paralelan upit, nezavisan od profila).
async function getProfile(req, res) {
  try {
    const [profile, favorites] = await Promise.all([
      userModel.findProfileById(req.params.id),
      favoriteModel.findForUser(req.params.id),
    ]);
    if (!profile) {
      return res.status(404).json({ error: 'Korisnik ne postoji' });
    }
    res.json({ user: { ...profile, favoriteMovies: favorites } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// PUT /api/users/:id — korisnik može da menja samo svoj profil.
async function updateProfile(req, res) {
  try {
    if (req.params.id != req.userId) {
      return res.status(403).json({ error: 'Ne možeš menjati tuđi profil' });
    }

    const { username, avatarUrl, bio } = req.body;

    if (username !== undefined) {
      const existing = await userModel.findByUsername(username);
      if (existing && existing.id !== req.userId) {
        return res.status(409).json({ error: 'Username je već zauzet' });
      }
    }

    const updated = await userModel.update(req.userId, { username, avatarUrl, bio });
    res.json({ user: updated });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// PUT /api/users/:id/favorites — zamenjuje top 4 omiljena filma.
// Samo vlasnik profila. Body: { movieIds: [12, 45, 3, 88] } — redosled
// u nizu određuje redosled prikaza (1. mesto, 2. mesto, itd).
async function setFavorites(req, res) {
  try {
    if (req.params.id != req.userId) {
      return res.status(403).json({ error: 'Ne možeš menjati tuđe omiljene filmove' });
    }

    const { movieIds } = req.body;
    if (!Array.isArray(movieIds)) {
      return res.status(400).json({ error: 'movieIds mora biti niz ID-jeva filmova' });
    }
    if (movieIds.length > MAX_FAVORITES) {
      return res.status(400).json({ error: `Maksimalno ${MAX_FAVORITES} omiljena filma` });
    }
    const uniqueIds = new Set(movieIds);
    if (uniqueIds.size !== movieIds.length) {
      return res.status(400).json({ error: 'Isti film ne može biti dodat dvaput' });
    }

    const favorites = await favoriteModel.setForUser(req.userId, movieIds);
    res.json({ favoriteMovies: favorites });
  } catch (err) {
    // Foreign key violation (nepostojeći movieId) ima kod '23503' u pg-u.
    if (err.code === '23503') {
      return res.status(400).json({ error: 'Jedan ili više movieId ne postoje' });
    }
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// GET /api/users/search?q=... — javno.
async function searchUsers(req, res) {
  try {
    const query = req.query.q;
    if (!query || !query.trim()) {
      return res.status(400).json({ error: 'Query parametar q je obavezan' });
    }
    const limit = parseInt(req.query.limit, 10) || 20;
    const offset = parseInt(req.query.offset, 10) || 0;
    const users = await userModel.search(query.trim(), { limit, offset });
    res.json({ users });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

module.exports = {
  getProfile,
  updateProfile,
  setFavorites,
  searchUsers,
};