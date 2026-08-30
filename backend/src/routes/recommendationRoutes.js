const express = require('express');
const router = express.Router();
const recommendationController = require('../controllers/recommendationController');
const authMiddleware = require('../middleware/authMiddleware');

router.get('/', authMiddleware, recommendationController.getRecommendations);

module.exports = router;
