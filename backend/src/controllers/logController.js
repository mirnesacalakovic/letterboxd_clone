const logService =
  require('../services/logService');

const MAX_REVIEW_LENGTH = 5000;
const MAX_TAGS = 10;
const MAX_TAG_LENGTH = 30;

function isValidMovieId(value) {
  return (
    Number.isInteger(value) &&
    value > 0
  );
}

function isValidWatchedDate(value) {
  if (
    typeof value !== 'string' ||
    !/^\d{4}-\d{2}-\d{2}$/.test(value)
  ) {
    return false;
  }

  const date =
    new Date(`${value}T00:00:00Z`);

  return (
    !Number.isNaN(date.getTime()) &&
    date <= new Date()
  );
}

function isValidRating(value) {
  if (value === null) {
    return true;
  }

  return (
    typeof value === 'number' &&
    value >= 0.5 &&
    value <= 5 &&
    Number.isInteger(value * 2)
  );
}

function normalizeTags(tags) {
  if (!Array.isArray(tags)) {
    return {
      error:
        'tags mora biti niz stringova',
    };
  }

  if (tags.length > MAX_TAGS) {
    return {
      error:
        `Maksimalno ${MAX_TAGS} tagova po diary unosu`,
    };
  }

  const normalized = [];

  for (const tag of tags) {
    if (
      typeof tag !== 'string' ||
      !tag.trim()
    ) {
      return {
        error:
          'Svaki tag mora biti neprazan string',
      };
    }

    const cleanTag =
      tag.trim().toLowerCase();

    if (
      cleanTag.length >
      MAX_TAG_LENGTH
    ) {
      return {
        error:
          `Tag ne sme biti duži od ${MAX_TAG_LENGTH} karaktera`,
      };
    }

    if (
      !normalized.includes(cleanTag)
    ) {
      normalized.push(cleanTag);
    }
  }

  return {
    tags: normalized,
  };
}

function validateLogBody(body) {
  if (
    !isValidMovieId(body.movieId)
  ) {
    return (
      'movieId mora biti pozitivan ceo broj'
    );
  }

  if (
    !isValidWatchedDate(
      body.watchedDate
    )
  ) {
    return (
      'watchedDate mora biti validan datum ' +
      '(YYYY-MM-DD) koji nije u budućnosti'
    );
  }

  if (
    !isValidRating(body.rating)
  ) {
    return (
      'rating mora biti null ili između ' +
      '0.5 i 5.0, u koracima od 0.5'
    );
  }

  if (
    typeof body.review !== 'string' ||
    body.review.length >
      MAX_REVIEW_LENGTH
  ) {
    return (
      `review mora biti string do ` +
      `${MAX_REVIEW_LENGTH} karaktera`
    );
  }

  const booleans = [
    body.liked,
    body.isRewatch,
    body.isSpoiler,
    body.commentsAllowed,
  ];

  if (
    booleans.some(
      (value) =>
        typeof value !== 'boolean'
    )
  ) {
    return (
      'liked, isRewatch, isSpoiler i ' +
      'commentsAllowed moraju biti boolean vrednosti'
    );
  }

  return null;
}

async function getState(req, res) {
  try {
    const movieId =
      Number.parseInt(
        req.params.movieId,
        10
      );

    if (!isValidMovieId(movieId)) {
      return res.status(400).json({
        error: 'Nevažeći movieId',
      });
    }

    const state =
      await logService.getState(
        req.userId,
        movieId
      );

    if (!state.movieExists) {
      return res.status(404).json({
        error: 'Film ne postoji',
      });
    }

    return res.json({
      state: {
        rating: state.rating,
        liked: state.liked,
        hasWatched:
          state.hasWatched,
      },
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      error:
        'Internal Server Error',
    });
  }
}

async function create(req, res) {
  try {
    const validationError =
      validateLogBody(req.body);

    if (validationError) {
      return res.status(400).json({
        error: validationError,
      });
    }

    const tagsResult =
      normalizeTags(req.body.tags);

    if (tagsResult.error) {
      return res.status(400).json({
        error: tagsResult.error,
      });
    }

    const result =
      await logService.logFilm({
        userId: req.userId,
        movieId:
          req.body.movieId,
        watchedDate:
          req.body.watchedDate,
        rating:
          req.body.rating,
        liked:
          req.body.liked,
        review:
          req.body.review.trim(),
        tags:
          tagsResult.tags,
        isRewatch:
          req.body.isRewatch,
        isSpoiler:
          req.body.isSpoiler,
        commentsAllowed:
          req.body.commentsAllowed,
      });

    return res
      .status(201)
      .json({
        message:
          'Film je dodat u Diary',
        ...result,
      });
  } catch (error) {
    if (
      error.code ===
      'MOVIE_NOT_FOUND'
    ) {
      return res.status(404).json({
        error: error.message,
      });
    }

    console.error(error);

    return res.status(500).json({
      error:
        'Internal Server Error',
    });
  }
}

module.exports = {
  getState,
  create,
};