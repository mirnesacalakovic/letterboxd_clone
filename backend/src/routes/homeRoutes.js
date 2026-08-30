const express = require('express');
const router = express.Router();
const homeController = require('../controllers/homeController');
const authMiddleware = require('../middleware/authMiddleware');

// authMiddleware je obavezan iako je "Popular this week" globalno
// (ne zavisi od korisnika) — jer su druge dve sekcije lične
// (zavise od toga koga korisnik prati), pa ceo endpoint zahteva login.
router.get('/', authMiddleware, homeController.getHome);

module.exports = router;
