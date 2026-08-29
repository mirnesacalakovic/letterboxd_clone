const ratingModel = require("../models/ratingModel");

// Dozvoljene vrednosti: 0.5, 1.0, 1.5, ..., 4.5, 5.0
function isValidRating(value) {
  return (
    typeof value === "number" &&
    value >= 0.5 &&
    value <= 5.0 &&
    Number.isInteger(value * 2)
  );
}

// POST /api/ratings — kreira novu ocenu. Ako korisnik već ima ocenu za
// taj film, vraća 409 (mora da koristi PUT da je izmeni, po specifikaciji).
async function create(req, res) {
  try {
    const { movieId, rating } = req.body;

    if (!movieId || rating === undefined) {
      return res.status(400).json({ error: "movieId i rating su obavezni" });
    }
    if (!isValidRating(rating)) {
      return res
        .status(400)
        .json({
          error: "rating mora biti između 0.5 i 5.0, u koracima od 0.5",
        });
    }

    const existing = await ratingModel.findByUserAndMovie(req.userId, movieId);
    if (existing) {
      return res
        .status(409)
        .json({
          error: "Već postoji ocena za ovaj film. Koristi PUT da je izmeniš.",
        });
    }

    const newRating = await ratingModel.create({
      userId: req.userId,
      movieId,
      rating,
    });
    res.status(201).json({ rating: newRating });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Internal Server Error" });
  }
}

// PUT /api/ratings/:id — izmena postojeće ocene. Samo vlasnik ocene sme
// da je izmeni (403 ako pokuša neko drugi).
async function update(req, res) {
  try {
    const { rating } = req.body;

    if (rating === undefined || !isValidRating(rating)) {
      return res
        .status(400)
        .json({
          error: "rating mora biti između 0.5 i 5.0, u koracima od 0.5",
        });
    }

    const existing = await ratingModel.findById(req.params.id);
    if (!existing) {
      return res.status(404).json({ error: "Ocena ne postoji" });
    }
    if (existing.user_id !== req.userId) {
      return res
        .status(403)
        .json({ error: "Nemaš pravo da menjaš tuđu ocenu" });
    }

    const updated = await ratingModel.update(req.params.id, rating);
    res.json({ rating: updated });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Internal Server Error" });
  }
}

// DELETE /api/ratings/:id
async function remove(req, res) {
  try {
    const existing = await ratingModel.findById(req.params.id);
    if (!existing) {
      return res.status(404).json({ error: "Ocena ne postoji" });
    }
    if (existing.user_id !== req.userId) {
      return res
        .status(403)
        .json({ error: "Nemaš pravo da brišeš tuđu ocenu" });
    }

    await ratingModel.remove(req.params.id);
    res.status(200).json({ message: "Ocena obrisana" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Internal Server Error" });
  }
}

// GET /api/ratings/movie/:movieId — javni endpoint, svi mogu da vide
// sve ocene za jedan film.
async function getForMovie(req, res) {
  try {
    const ratings = await ratingModel.findAllForMovie(req.params.movieId);
    res.json({ ratings });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Internal Server Error" });
  }
}

module.exports = {
  create,
  update,
  remove,
  getForMovie,
};
