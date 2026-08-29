const express = require('express');
const router = express.Router();
const movieController = require('../controllers/movieController');

// VAŽNO: /search mora biti definisan PRE /:id, inače Express
// tumači "search" kao vrednost za :id parametar.
router.get('/search', movieController.searchMovies);
router.get('/:id', movieController.getById);
router.get('/', movieController.getAll);

module.exports = router;