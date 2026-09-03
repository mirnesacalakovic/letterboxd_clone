const express =
  require('express');

const logController =
  require('../controllers/logController');

const authMiddleware =
  require('../middleware/authMiddleware');

const router =
  express.Router();

router.get(
  '/:movieId',
  authMiddleware,
  logController.getState
);

router.post(
  '/',
  authMiddleware,
  logController.create
);

module.exports = router;