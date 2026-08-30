const express = require('express');
const router = express.Router();
const reviewController = require('../controllers/reviewController');
const authMiddleware = require('../middleware/authMiddleware');

// GET je javno (svako može da čita recenzije), sve ostalo zahteva login.
router.get('/:id', reviewController.getById);
router.post('/', authMiddleware, reviewController.create);
router.put('/:id', authMiddleware, reviewController.update);
router.delete('/:id', authMiddleware, reviewController.remove);
router.post('/:id/like', authMiddleware, reviewController.like);
router.delete('/:id/like', authMiddleware, reviewController.unlike);

module.exports = router;