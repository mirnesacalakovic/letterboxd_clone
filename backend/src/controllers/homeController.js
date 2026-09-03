const homeModel = require('../models/homeModel');

// GET /api/home
// Everything needed by all four Home tabs is loaded in parallel so switching
// Films / Reviews / Lists / Journal does not trigger a stack of extra requests.
async function getHome(req, res) {
  try {
    const [
      popularThisWeek,
      newFromFriends,
      popularWithFriends,
      popularReviews,
      popularLists,
    ] = await Promise.all([
      homeModel.getPopularThisWeek(12),
      homeModel.getNewFromFriends(req.userId, 20),
      homeModel.getPopularWithFriends(req.userId, 12),
      homeModel.getPopularReviews(20),
      homeModel.getPopularLists(20),
    ]);

    return res.json({
      popularThisWeek,
      newFromFriends,
      popularWithFriends,
      popularReviews,
      popularLists,
    });
  } catch (err) {
    console.error(err);

    return res.status(500).json({
      error: 'Internal Server Error',
    });
  }
}

module.exports = {
  getHome,
};