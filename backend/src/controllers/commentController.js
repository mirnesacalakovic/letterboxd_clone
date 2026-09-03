const commentModel =
  require('../models/commentModel');

const reviewModel =
  require('../models/reviewModel');

const MAX_COMMENT_LENGTH = 1000;

function validateComment(content) {
  if (
    !content?.trim()
  ) {
    return 'content je obavezan';
  }

  if (
    content.length >
    MAX_COMMENT_LENGTH
  ) {
    return (
      `content ne sme biti duži od ` +
      `${MAX_COMMENT_LENGTH} karaktera`
    );
  }

  return null;
}

// POST /api/reviews/:reviewId/comments
async function create(req, res) {
  try {
    const { reviewId } =
      req.params;

    const { content } =
      req.body;

    const validationError =
      validateComment(content);

    if (validationError) {
      return res.status(400).json({
        error: validationError,
      });
    }

    const review =
      await reviewModel.findById(
        reviewId
      );

    if (!review) {
      return res.status(404).json({
        error:
          'Recenzija ne postoji',
      });
    }

    if (
      review.comments_enabled ===
      false
    ) {
      return res.status(403).json({
        error:
          'Autor je isključio odgovore na ovu recenziju',
      });
    }

    const comment =
      await commentModel.create({
        reviewId,
        userId: req.userId,
        content: content.trim(),
      });

    return res
      .status(201)
      .json({
        comment,
      });
  } catch (err) {
    console.error(err);

    return res.status(500).json({
      error:
        'Internal Server Error',
    });
  }
}

// GET /api/reviews/:reviewId/comments
async function getAllForReview(
  req,
  res
) {
  try {
    const review =
      await reviewModel.findById(
        req.params.reviewId
      );

    if (!review) {
      return res.status(404).json({
        error:
          'Recenzija ne postoji',
      });
    }

    const comments =
      await commentModel
        .findAllForReview(
          req.params.reviewId
        );

    return res.json({
      comments,
    });
  } catch (err) {
    console.error(err);

    return res.status(500).json({
      error:
        'Internal Server Error',
    });
  }
}

// PUT /api/comments/:id
async function update(req, res) {
  try {
    const { content } =
      req.body;

    const validationError =
      validateComment(content);

    if (validationError) {
      return res.status(400).json({
        error: validationError,
      });
    }

    const existing =
      await commentModel.findById(
        req.params.id
      );

    if (!existing) {
      return res.status(404).json({
        error:
          'Komentar ne postoji',
      });
    }

    if (
      existing.user_id !==
      req.userId
    ) {
      return res.status(403).json({
        error:
          'Nemaš pravo da menjaš tuđ komentar',
      });
    }

    const updated =
      await commentModel.update(
        req.params.id,
        content.trim()
      );

    return res.json({
      comment: updated,
    });
  } catch (err) {
    console.error(err);

    return res.status(500).json({
      error:
        'Internal Server Error',
    });
  }
}

// DELETE /api/comments/:id
async function remove(req, res) {
  try {
    const existing =
      await commentModel.findById(
        req.params.id
      );

    if (!existing) {
      return res.status(404).json({
        error:
          'Komentar ne postoji',
      });
    }

    if (
      existing.user_id !==
      req.userId
    ) {
      return res.status(403).json({
        error:
          'Nemaš pravo da brišeš tuđ komentar',
      });
    }

    await commentModel.remove(
      req.params.id
    );

    return res.json({
      message:
        'Komentar obrisan',
    });
  } catch (err) {
    console.error(err);

    return res.status(500).json({
      error:
        'Internal Server Error',
    });
  }
}

module.exports = {
  create,
  getAllForReview,
  update,
  remove,
};