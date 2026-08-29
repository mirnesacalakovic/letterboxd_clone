const express = require('express');
const router = express.Router();
const watchedController = require('../controllers/watchedController');
const authMiddleware = require('../middleware/authMiddleware');

// Sve rute u ovom modulu zahtevaju login — "watched" je uvek vezan
// za trenutno ulogovanog korisnika (req.userId), nema javnog pregleda.
router.use(authMiddleware);

router.get('/', watchedController.getAllForUser);
router.post('/:movieId', watchedController.markAsWatched);
router.delete('/:movieId', watchedController.removeWatched);

module.exports = router;