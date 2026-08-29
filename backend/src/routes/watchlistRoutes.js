const express = require('express');
const router = express.Router();
const watchlistController = require('../controllers/watchlistController');
const authMiddleware = require('../middleware/authMiddleware');

// Sve rute zahtevaju login — isti obrazac kao watchedRoutes.
router.use(authMiddleware);

router.get('/', watchlistController.getAllForUser);
router.post('/:movieId', watchlistController.addToWatchlist);
router.delete('/:movieId', watchlistController.removeFromWatchlist);

module.exports = router;