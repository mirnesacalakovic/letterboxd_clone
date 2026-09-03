const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const followController = require('../controllers/followController');
const diaryController = require('../controllers/diaryController');
const reviewController = require('../controllers/reviewController');
const movieController = require('../controllers/movieController');
const authMiddleware = require('../middleware/authMiddleware');

// Javne rute — pregled profila, pratilaca, dnevnika, recenzija i
// lajkova ne zahteva login (isti obrazac kao pravi Letterboxd profil
// meni: Films/Diary/Reviews/Lists/Watchlist/Likes/Following/Followers).
router.get('/search', userController.searchUsers);
router.get('/:id', userController.getProfile);
router.get('/:id/followers', followController.getFollowers);
router.get('/:id/following', followController.getFollowing);
router.get('/:id/diary', diaryController.getDiaryForUser);
router.get('/:id/reviews', reviewController.getReviewsForUser);
router.get('/:id/likes', movieController.getLikesForUser);

// Zaštićene rute — izmena profila i follow/unfollow zahtevaju login.
router.put('/:id', authMiddleware, userController.updateProfile);
router.put('/:id/favorites', authMiddleware, userController.setFavorites);
router.post('/:id/follow', authMiddleware, followController.follow);
router.delete('/:id/follow', authMiddleware, followController.unfollow);
router.post(
  '/:id/avatar',
  authMiddleware,

  express.raw({
    type: 'image/*',
    limit: '5mb',
  }),

  userController.uploadAvatar
);

module.exports = router;