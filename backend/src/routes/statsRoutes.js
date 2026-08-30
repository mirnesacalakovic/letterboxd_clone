const express = require('express');
const router = express.Router();
const statsController = require('../controllers/statsController');

// Javno, kao i profil (GET /api/users/:id) — nema authMiddleware.
router.get('/:userId', statsController.getStats);

module.exports = router;
