const homeModel = require('../models/homeModel');

// GET /api/home — sve tri sekcije se učitavaju paralelno (Promise.all),
// nema razloga da čekaju jedna drugu jer su nezavisni upiti.
async function getHome(req, res) {
  try {
    const [popularThisWeek, newFromFriends, popularWithFriends] = await Promise.all([
      homeModel.getPopularThisWeek(10),
      homeModel.getNewFromFriends(req.userId, 20),
      homeModel.getPopularWithFriends(req.userId, 10),
    ]);

    res.json({ popularThisWeek, newFromFriends, popularWithFriends });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

module.exports = {
  getHome,
};
