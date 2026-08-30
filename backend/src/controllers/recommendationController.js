const recommendationService = require('../services/recommendationService');

// GET /api/recommendations — lično, zavisi od korisnikovih ocena.
async function getRecommendations(req, res) {
  try {
    const result = await recommendationService.getRecommendations(req.userId);
    res.json(result);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

module.exports = {
  getRecommendations,
};
