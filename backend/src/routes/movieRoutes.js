const express = require('express');
const router = express.Router();
const movieController = require('../controllers/movieController');
const authMiddleware = require('../middleware/authMiddleware');

// VAŽNO: /search mora biti definisan PRE /:id, inače Express
// tumači "search" kao vrednost za :id parametar.
router.get('/search', movieController.searchMovies);
router.get('/:id/reviews', movieController.getReviews);
router.get('/:id/similar', movieController.getSimilar);
router.get('/:id', movieController.getById);
router.get('/', movieController.getAll);
router.post('/:id/like', authMiddleware, movieController.likeMovie);
router.delete('/:id/like', authMiddleware, movieController.unlikeMovie);

module.exports = router;