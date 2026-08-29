const express = require("express");
const router = express.Router();
const ratingController = require("../controllers/ratingController");
const authMiddleware = require("../middleware/authMiddleware");

// VAŽNO: /movie/:movieId mora biti definisan PRE /:id (isti razlog
// kao kod movieRoutes — Express bi inače "movie" protumačio kao :id).
router.get("/movie/:movieId", ratingController.getForMovie);
router.post("/", authMiddleware, ratingController.create);
router.put("/:id", authMiddleware, ratingController.update);
router.delete("/:id", authMiddleware, ratingController.remove);

module.exports = router;
