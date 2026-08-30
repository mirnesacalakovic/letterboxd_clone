const express = require('express');
const router = express.Router();
const diaryController = require('../controllers/diaryController');
const authMiddleware = require('../middleware/authMiddleware');

// Sve ovde je lično (sopstveni dnevnik) — zahteva login.
// Za tuđ (javni) dnevnik videti GET /api/users/:id/diary u userRoutes.js.
router.get('/', authMiddleware, diaryController.getOwnDiary);
router.post('/', authMiddleware, diaryController.create);
router.put('/:id', authMiddleware, diaryController.update);
router.delete('/:id', authMiddleware, diaryController.remove);

module.exports = router;
