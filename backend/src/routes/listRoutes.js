const express = require('express');
const router = express.Router();
const listController = require('../controllers/listController');
const authMiddleware = require('../middleware/authMiddleware');
const optionalAuthMiddleware = require('../middleware/optionalAuthMiddleware');

router.get('/', authMiddleware, listController.getAllForCurrentUser);
router.post('/', authMiddleware, listController.create);
// VAŽNO: /discover mora biti PRE /:id (isti razlog kao movieRoutes/search).
router.get('/discover', listController.discover);
router.get('/:id', optionalAuthMiddleware, listController.getById);
router.put('/:id', authMiddleware, listController.update);
router.delete('/:id', authMiddleware, listController.remove);
router.post('/:id/movies/:movieId', authMiddleware, listController.addMovie);
router.delete('/:id/movies/:movieId', authMiddleware, listController.removeMovie);

module.exports = router;