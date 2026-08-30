const express = require('express');
const router = express.Router();
const commentController = require('../controllers/commentController');
const authMiddleware = require('../middleware/authMiddleware');

router.put('/:id', authMiddleware, commentController.update);
router.delete('/:id', authMiddleware, commentController.remove);

module.exports = router;
