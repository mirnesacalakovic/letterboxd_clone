const userModel = require('../models/userModel');

// GET /api/users/:id — javni profil, svako može da vidi.
async function getProfile(req, res) {
  try {
    const profile = await userModel.findProfileById(req.params.id);
    if (!profile) {
      return res.status(404).json({ error: 'Korisnik ne postoji' });
    }
    res.json({ user: profile });
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

module.exports = {
  getProfile,
  updateProfile,
};