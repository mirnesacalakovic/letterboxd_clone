const feedModel = require('../models/feedModel');

// GET /api/feed — lično, zavisi od toga koga trenutni korisnik prati.
async function getFeed(req, res) {
  try {
    const limit = parseInt(req.query.limit, 10) || 20;
    const offset = parseInt(req.query.offset, 10) || 0;
    const activities = await feedModel.getFeedForUser(req.userId, { limit, offset });
    res.json({ activities });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

module.exports = {
  getFeed,
};
