const express =
  require('express');

const router =
  express.Router();

const movieController =
  require(
    '../controllers/movieController'
  );

const movieCommunityController =
  require(
    '../controllers/movieCommunityController'
  );

const authMiddleware =
  require(
    '../middleware/authMiddleware'
  );

const optionalAuthMiddleware =
  require(
    '../middleware/optionalAuthMiddleware'
  );

// /search mora biti pre /:id,
// da Express ne protumači
// "search" kao movie id.
router.get(
  '/search',
  movieController.searchMovies
);

// Movie page je javna,
// ali ako postoji JWT,
// vraća i korisničko stanje.
router.get(
  '/:id/page',
  optionalAuthMiddleware,
  movieController.getPage
);

// SVI korisnici koji su označili
// film kao watched.
//
// Ako postoji JWT,
// svaki member dobija:
// is_following
// is_current_user
router.get(
  '/:id/members',
  optionalAuthMiddleware,
  movieCommunityController.getMembers
);

// Sve JAVNE liste
// koje sadrže film.
router.get(
  '/:id/lists',
  optionalAuthMiddleware,
  movieCommunityController.getLists
);

// Reviews su javni,
// ali JWT omogućava
// Friends / You / Liked filtere.
router.get(
  '/:id/reviews',
  optionalAuthMiddleware,
  movieController.getReviews
);

router.get(
  '/:id/similar',
  movieController.getSimilar
);

router.get(
  '/:id',
  movieController.getById
);

router.get(
  '/',
  movieController.getAll
);

router.post(
  '/:id/like',
  authMiddleware,
  movieController.likeMovie
);

router.delete(
  '/:id/like',
  authMiddleware,
  movieController.unlikeMovie
);

module.exports = router;