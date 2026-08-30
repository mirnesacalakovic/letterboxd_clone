const reviewModel = require('../models/reviewModel');
const reviewLikeModel = require('../models/reviewLikeModel');
const ratingModel = require('../models/ratingModel');
const reviewService = require('../services/reviewService');

// Ograničenje dužine recenzije — sprečava DoS pokušaje slanja
// ogromnog teksta (npr. nekoliko MB) kao "review".
const MAX_REVIEW_LENGTH = 5000;
const MAX_TAGS = 10;
const MAX_TAG_LENGTH = 30;

// Isti pravila kao u ratingController — čuvamo ovde duplirano da
// modul ostane samostalan (mala duplikacija, izbegava cross-import).
function isValidRating(value) {
  return (
    typeof value === 'number' &&
    value >= 0.5 &&
    value <= 5.0 &&
    Number.isInteger(value * 2)
  );
}

// Validira tags niz: mora biti niz stringova, razuman broj, razumna dužina.
function validateTags(tags) {
  if (tags === undefined) return { valid: true, tags: [] };
  if (!Array.isArray(tags)) return { valid: false, error: 'tags mora biti niz stringova' };
  if (tags.length > MAX_TAGS) return { valid: false, error: `Maksimalno ${MAX_TAGS} tagova po recenziji` };
  for (const tag of tags) {
    if (typeof tag !== 'string' || !tag.trim()) {
      return { valid: false, error: 'Svaki tag mora biti neprazan string' };
    }
    if (tag.length > MAX_TAG_LENGTH) {
      return { valid: false, error: `Tag ne sme biti duži od ${MAX_TAG_LENGTH} karaktera` };
    }
  }
  return { valid: true, tags: tags.map((t) => t.trim().toLowerCase()) };
}

// POST /api/reviews — podržava opcioni "rating" u istom pozivu
// (kombinovan unos, kao na pravom Letterboxd-u).
async function create(req, res) {
  try {
    const { movieId, content, isSpoiler, tags, rating } = req.body;

    if (!movieId || !content || !content.trim()) {
      return res.status(400).json({ error: 'movieId i content su obavezni' });
    }
    if (content.length > MAX_REVIEW_LENGTH) {
      return res.status(400).json({ error: `content ne sme biti duži od ${MAX_REVIEW_LENGTH} karaktera` });
    }

    const tagsResult = validateTags(tags);
    if (!tagsResult.valid) {
      return res.status(400).json({ error: tagsResult.error });
    }

    if (rating !== undefined && !isValidRating(rating)) {
      return res.status(400).json({ error: 'rating mora biti između 0.5 i 5.0, u koracima od 0.5' });
    }

    const existingReview = await reviewModel.findByUserAndMovie(req.userId, movieId);
    if (existingReview) {
      return res.status(409).json({ error: 'Već postoji recenzija za ovaj film. Koristi PUT da je izmeniš.' });
    }

    if (rating !== undefined) {
      const existingRating = await ratingModel.findByUserAndMovie(req.userId, movieId);
      if (existingRating) {
        return res.status(409).json({ error: 'Već postoji ocena za ovaj film. Ukloni je pre kombinovanog unosa, ili pošalji recenziju bez rating polja.' });
      }
    }

    const { review, rating: createdRating } = await reviewService.createReviewWithRating({
      userId: req.userId,
      movieId,
      content: content.trim(),
      isSpoiler: !!isSpoiler,
      tags: tagsResult.tags,
      rating,
    });

    res.status(201).json({ review, rating: createdRating });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// GET /api/reviews/:id — javno, svako može da pročita jednu recenziju.
async function getById(req, res) {
  try {
    const review = await reviewModel.findById(req.params.id);
    if (!review) {
      return res.status(404).json({ error: 'Recenzija ne postoji' });
    }
    res.json({ review });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// PUT /api/reviews/:id — samo vlasnik sme da izmeni.
async function update(req, res) {
  try {
    const { content, isSpoiler, tags } = req.body;

    if (content !== undefined && (!content.trim() || content.length > MAX_REVIEW_LENGTH)) {
      return res.status(400).json({ error: `content mora biti neprazan i najviše ${MAX_REVIEW_LENGTH} karaktera` });
    }

    const tagsResult = validateTags(tags);
    if (!tagsResult.valid) {
      return res.status(400).json({ error: tagsResult.error });
    }

    const existing = await reviewModel.findById(req.params.id);
    if (!existing) {
      return res.status(404).json({ error: 'Recenzija ne postoji' });
    }
    if (existing.user_id !== req.userId) {
      return res.status(403).json({ error: 'Nemaš pravo da menjaš tuđu recenziju' });
    }

    const updated = await reviewModel.update(req.params.id, {
      content: content !== undefined ? content.trim() : undefined,
      isSpoiler,
      tags: tags !== undefined ? tagsResult.tags : undefined,
    });
    res.json({ review: updated });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// DELETE /api/reviews/:id — samo vlasnik sme da obriše.
async function remove(req, res) {
  try {
    const existing = await reviewModel.findById(req.params.id);
    if (!existing) {
      return res.status(404).json({ error: 'Recenzija ne postoji' });
    }
    if (existing.user_id !== req.userId) {
      return res.status(403).json({ error: 'Nemaš pravo da brišeš tuđu recenziju' });
    }

    await reviewModel.remove(req.params.id);
    res.json({ message: 'Recenzija obrisana' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// POST /api/reviews/:id/like
async function like(req, res) {
  try {
    const review = await reviewModel.findById(req.params.id);
    if (!review) {
      return res.status(404).json({ error: 'Recenzija ne postoji' });
    }

    const existing = await reviewLikeModel.findByUserAndReview(req.userId, req.params.id);
    if (existing) {
      return res.status(409).json({ error: 'Već si lajkovala ovu recenziju' });
    }

    const like = await reviewLikeModel.likeReview(req.userId, req.params.id);
    res.status(201).json({ like });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// DELETE /api/reviews/:id/like
async function unlike(req, res) {
  try {
    const existing = await reviewLikeModel.findByUserAndReview(req.userId, req.params.id);
    if (!existing) {
      return res.status(404).json({ error: 'Nisi lajkovala ovu recenziju' });
    }

    await reviewLikeModel.unlikeReview(req.userId, req.params.id);
    res.json({ message: 'Lajk uklonjen' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

module.exports = {
  create,
  getById,
  update,
  remove,
  like,
  unlike,
};
