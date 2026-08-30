const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const followController = require('../controllers/followController');
const diaryController = require('../controllers/diaryController');
const authMiddleware = require('../middleware/authMiddleware');

// Javne rute — pregled profila, pratilaca i dnevnika ne zahtevaju login.
router.get('/:id', userController.getProfile);
router.get('/:id/followers', followController.getFollowers);
router.get('/:id/following', followController.getFollowing);
router.get('/:id/diary', diaryController.getDiaryForUser);

// Zaštićene rute — izmena profila i follow/unfollow zahtevaju login.
router.put('/:id', authMiddleware, userController.updateProfile);
router.put('/:id/favorites', authMiddleware, userController.setFavorites);
router.post('/:id/follow', authMiddleware, followController.follow);
router.delete('/:id/follow', authMiddleware, followController.unfollow);

module.exports = router;