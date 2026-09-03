const movieModel =
  require('../models/movieModel');

const movieCommunityModel =
  require('../models/movieCommunityModel');

function parseLimit(
  value,
  fallback,
  max
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

function parseOffset(value) {
  const parsed =
    Number.parseInt(
      value,
      10
    );

  return (
    Number.isInteger(parsed) &&
    parsed >= 0
  )
    ? parsed
    : 0;
}

async function ensureMovieExists(
  movieId,
  res
) {
  const movie =
    await movieModel.findById(
      movieId
    );

  if (movie) {
    return true;
  }

  res.status(404).json({
    error:
      'Film ne postoji',
  });

  return false;
}

// GET /api/movies/:id/members
async function getMembers(
  req,
  res
) {
  try {
    const exists =
      await ensureMovieExists(
        req.params.id,
        res
      );

    if (!exists) {
      return;
    }

    const limit =
      parseLimit(
        req.query.limit,
        100,
        200
      );

    const offset =
      parseOffset(
        req.query.offset
      );

    const result =
      await movieCommunityModel
        .findMembers(
          req.params.id,
          req.userId,
          {
            limit,
            offset,
          }
        );

    return res.json(result);
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

// GET /api/movies/:id/lists
async function getLists(
  req,
  res
) {
  try {
    const exists =
      await ensureMovieExists(
        req.params.id,
        res
      );

    if (!exists) {
      return;
    }

    const limit =
      parseLimit(
        req.query.limit,
        50,
        100
      );

    const offset =
      parseOffset(
        req.query.offset
      );

    const result =
      await movieCommunityModel
        .findListsContainingMovie(
          req.params.id,
          {
            limit,
            offset,
          }
        );

    return res.json(result);
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
  getMembers,
  getLists,
};