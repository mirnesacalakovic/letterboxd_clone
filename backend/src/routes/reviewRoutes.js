const express = require('express');
const router = express.Router();
const reviewController = require('../controllers/reviewController');
const commentController = require('../controllers/commentController');
const authMiddleware = require('../middleware/authMiddleware');

// GET je javno (svako može da čita recenzije), sve ostalo zahteva login.
router.get('/:id', reviewController.getById);
router.post('/', authMiddleware, reviewController.create);
router.put('/:id', authMiddleware, reviewController.update);
router.delete('/:id', authMiddleware, reviewController.remove);
router.post('/:id/like', authMiddleware, reviewController.like);
router.delete('/:id/like', authMiddleware, reviewController.unlike);

// Komentari — ugnježdeni pod recenzijom za create/list (potreban je
// reviewId iz putanje). Edit/delete idu preko odvojenih /api/comments/:id
// ruta (videti commentRoutes.js) jer im ne treba reviewId.
router.get('/:reviewId/comments', commentController.getAllForReview);
router.post('/:reviewId/comments', authMiddleware, commentController.create);

module.exports = router;