const followModel = require('../models/followModel');
const userModel = require('../models/userModel');

// POST /api/users/:id/follow
async function follow(req, res) {
  try {
    const targetId = req.params.id;

    if (String(targetId) === String(req.userId)) {
      return res.status(400).json({ error: 'Ne možeš pratiti samog sebe' });
    }

    const targetUser = await userModel.findById(targetId);
    if (!targetUser) {
      return res.status(404).json({ error: 'Korisnik ne postoji' });
    }

    const existing = await followModel.findFollow(req.userId, targetId);
    if (existing) {
      return res.status(409).json({ error: 'Već pratiš ovog korisnika' });
    }

    const follow = await followModel.follow(req.userId, targetId);
    res.status(201).json({ follow });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// DELETE /api/users/:id/follow
async function unfollow(req, res) {
  try {
    const targetId = req.params.id;

    const existing = await followModel.findFollow(req.userId, targetId);
    if (!existing) {
      return res.status(404).json({ error: 'Ne pratiš ovog korisnika' });
    }

    await followModel.unfollow(req.userId, targetId);
    res.json({ message: 'Otpraćen korisnik' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// GET /api/users/:id/followers — javno.
async function getFollowers(req, res) {
  try {
    const followers = await followModel.findFollowers(req.params.id);
    res.json({ followers });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// GET /api/users/:id/following — javno.
async function getFollowing(req, res) {
  try {
    const following = await followModel.findFollowing(req.params.id);
    res.json({ following });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

module.exports = {
  follow,
  unfollow,
  getFollowers,
  getFollowing,
};