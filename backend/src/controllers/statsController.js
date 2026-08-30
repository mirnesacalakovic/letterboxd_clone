const statsModel = require('../models/statsModel');
const userModel = require('../models/userModel');

// GET /api/stats/:userId?year=2025 — javno (kao i profil), year je opcion.
async function getStats(req, res) {
  try {
    const user = await userModel.findById(req.params.userId);
    if (!user) {
      return res.status(404).json({ error: 'Korisnik ne postoji' });
    }

    let year;
    if (req.query.year !== undefined) {
      year = parseInt(req.query.year, 10);
      const currentYear = new Date().getFullYear();
      if (isNaN(year) || year < 1900 || year > currentYear) {
        return res.status(400).json({ error: `year mora biti između 1900 i ${currentYear}` });
      }
    }

    const stats = await statsModel.getUserStats(req.params.userId, year);
    res.json({ year: year || 'all-time', stats });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

module.exports = {
  getStats,
};
