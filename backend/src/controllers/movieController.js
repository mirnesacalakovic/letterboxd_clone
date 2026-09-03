const movieModel =
  require('../models/movieModel');

const reviewModel =
  require('../models/reviewModel');

const movieLikeModel =
  require('../models/movieLikeModel');

const similarMoviesService =
  require(
    '../services/similarMoviesService'
  );

const REVIEW_FILTERS =
  new Set([
    'everyone',
    'friends',
    'you',
    'liked',
  ]);

function parseLimit(
  value,
  fallback = 50,
  max = 100
) {
  const parsed =
    Number.parseInt(
      value,
      10
    );

  if (
    !Number.isInteger(parsed) ||
    parsed < 1
  ) {
    return fallback;
  }

  return Math.min(
    parsed,
    max
  );
}

async function getAll(
  req,
  res
) {
  try {
    const limit =
      Number.parseInt(
        req.query.limit,
        10
      ) || 20;

    const offset =
      Number.parseInt(
        req.query.offset,
        10
      ) || 0;

    const decade =
      req.query.decade
        ? Number.parseInt(
            req.query.decade,
            10
          )
        : undefined;

    if (
      decade !== undefined &&
      (
        Number.isNaN(decade) ||
        decade % 10 !== 0
      )
    ) {
      return res
        .status(400)
        .json({
          error:
            'decade mora biti broj deljiv sa 10, npr. 1990',
        });
    }

    const minRating =
      req.query.minRating
        ? Number.parseFloat(
            req.query.minRating
          )
        : undefined;

    if (
      minRating !== undefined &&
      (
        Number.isNaN(
          minRating
        ) ||
        minRating < 0.5 ||
        minRating > 5.0
      )
    ) {
      return res
        .status(400)
        .json({
          error:
            'minRating mora biti između 0.5 i 5.0',
        });
    }

    const sortBy =
      [
        'newest',
        'rating',
        'popular',
        'title',
      ].includes(
        req.query.sortBy
      )
        ? req.query.sortBy
        : 'title';

    const {
      movies,
      total,
    } =
      await movieModel.findAll({
        limit,
        offset,
        decade,
        minRating,
        sortBy,
      });

    return res.json({
      movies,
      total,
    });
  } catch (err) {
    console.error(err);

    return res
      .status(500)
      .json({
        error:
          'Internal Server Error',
      });
  }
}

async function getById(
  req,
  res
) {
  try {
    const movie =
      await movieModel.findById(
        req.params.id
      );

    if (!movie) {
      return res
        .status(404)
        .json({
          error:
            'Film ne postoji',
        });
    }

    return res.json({
      movie,
    });
  } catch (err) {
    console.error(err);

    return res
      .status(500)
      .json({
        error:
          'Internal Server Error',
      });
  }
}

async function getPage(
  req,
  res
) {
  try {
    const movie =
      await movieModel.findById(
        req.params.id
      );

    if (!movie) {
      return res
        .status(404)
        .json({
          error:
            'Film ne postoji',
        });
    }

    const page =
      await movieModel.findPageData(
        req.params.id,
        req.userId
      );

    return res.json({
      movie,
      ...page,
    });
  } catch (err) {
    console.error(err);

    return res
      .status(500)
      .json({
        error:
          'Internal Server Error',
      });
  }
}

async function searchMovies(
  req,
  res
) {
  try {
    const query =
      req.query.q;

    if (!query?.trim()) {
      return res
        .status(400)
        .json({
          error:
            'Query parametar q je obavezan',
        });
    }

    const limit =
      Number.parseInt(
        req.query.limit,
        10
      ) || 20;

    const offset =
      Number.parseInt(
        req.query.offset,
        10
      ) || 0;

    const {
      movies,
      total,
    } =
      await movieModel.search(
        query.trim(),
        {
          limit,
          offset,
        }
      );

    return res.json({
      movies,
      total,
    });
  } catch (err) {
    console.error(err);

    return res
      .status(500)
      .json({
        error:
          'Internal Server Error',
      });
  }
}

async function getReviews(
  req,
  res
) {
  try {
    const movie =
      await movieModel.findById(
        req.params.id
      );

    if (!movie) {
      return res
        .status(404)
        .json({
          error:
            'Film ne postoji',
        });
    }

    const sortBy =
      req.query.sortBy ===
      'mostLiked'
        ? 'mostLiked'
        : 'newest';

    const filter =
      REVIEW_FILTERS.has(
        req.query.filter
      )
        ? req.query.filter
        : 'everyone';

    const limit =
      parseLimit(
        req.query.limit
      );

    const reviews =
      await reviewModel
        .findAllForMovie(
          req.params.id,
          {
            sortBy,
            filter,

            viewerUserId:
              req.userId || null,

            limit,
          }
        );

    return res.json({
      reviews,
    });
  } catch (err) {
    console.error(err);

    return res
      .status(500)
      .json({
        error:
          'Internal Server Error',
      });
  }
}

async function likeMovie(
  req,
  res
) {
  try {
    const movie =
      await movieModel.findById(
        req.params.id
      );

    if (!movie) {
      return res
        .status(404)
        .json({
          error:
            'Film ne postoji',
        });
    }

    const existing =
      await movieLikeModel
        .findByUserAndMovie(
          req.userId,
          req.params.id
        );

    if (existing) {
      return res
        .status(409)
        .json({
          error:
            'Već si lajkovala ovaj film',
        });
    }

    const like =
      await movieLikeModel.likeMovie(
        req.userId,
        req.params.id
      );

    return res
      .status(201)
      .json({
        like,
      });
  } catch (err) {
    console.error(err);

    return res
      .status(500)
      .json({
        error:
          'Internal Server Error',
      });
  }
}

async function unlikeMovie(
  req,
  res
) {
  try {
    const existing =
      await movieLikeModel
        .findByUserAndMovie(
          req.userId,
          req.params.id
        );

    if (!existing) {
      return res
        .status(404)
        .json({
          error:
            'Nisi lajkovala ovaj film',
        });
    }

    await movieLikeModel
      .unlikeMovie(
        req.userId,
        req.params.id
      );

    return res.json({
      message:
        'Lajk uklonjen',
    });
  } catch (err) {
    console.error(err);

    return res
      .status(500)
      .json({
        error:
          'Internal Server Error',
      });
  }
}

async function getSimilar(
  req,
  res
) {
  try {
    const similar =
      await similarMoviesService
        .getSimilarMovies(
          req.params.id
        );

    if (similar === null) {
      return res
        .status(404)
        .json({
          error:
            'Film ne postoji',
        });
    }

    return res.json({
      similar,
    });
  } catch (err) {
    console.error(err);

    return res
      .status(500)
      .json({
        error:
          'Internal Server Error',
      });
  }
}

async function getLikesForUser(
  req,
  res
) {
  try {
    const likes =
      await movieLikeModel
        .findAllForUser(
          req.params.id
        );

    return res.json({
      likes,
    });
  } catch (err) {
    console.error(err);

    return res
      .status(500)
      .json({
        error:
          'Internal Server Error',
      });
  }
}

module.exports = {
  getAll,
  getById,
  getPage,
  searchMovies,
  getReviews,
  likeMovie,
  unlikeMovie,
  getSimilar,
  getLikesForUser,
};