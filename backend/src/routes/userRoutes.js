const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const followController = require('../controllers/followController');
const authMiddleware = require('../middleware/authMiddleware');

// Javne rute — pregled profila i liste pratilaca ne zahtevaju login.
router.get('/:id', userController.getProfile);
router.get('/:id/followers', followController.getFollowers);
router.get('/:id/following', followController.getFollowing);

// Zaštićene rute — izmena profila i follow/unfollow zahtevaju login.
router.put('/:id', authMiddleware, userController.updateProfile);
router.post('/:id/follow', authMiddleware, followController.follow);
router.delete('/:id/follow', authMiddleware, followController.unfollow);

module.exports = router;