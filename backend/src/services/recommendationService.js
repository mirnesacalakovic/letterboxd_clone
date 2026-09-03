const recommendationModel = require('../models/recommendationModel');
const {
  buildFeatureVector,
  cosineSimilarity,
  addWeightedVector,
} = require('./similarityUtils');

const MIN_RATINGS_FOR_PERSONALIZATION = 5;
const TOP_N_RECOMMENDATIONS = 12;

const REASON_SOURCE_LIMIT = 20;
const REASON_TOP_MATCHES = 3;
const REASON_TITLES_IN_TEXT = 2;

// The detailed Recommendations screen groups suggestions around up to six
// films the member rated highly, with up to five suggestions in each group.
const GROUP_SOURCE_LIMIT = 6;
const GROUP_MOVIES_LIMIT = 5;

function buildReasonText(topMatches) {
  const meaningfulMatches = topMatches.filter(
    (match) => match.similarity > 0
  );

  if (meaningfulMatches.length === 0) {
    return 'Based on your overall taste';
  }

  const uniqueTitles = [];

  for (const match of meaningfulMatches) {
    if (!uniqueTitles.includes(match.movie.title)) {
      uniqueTitles.push(match.movie.title);
    }

    if (uniqueTitles.length === REASON_TITLES_IN_TEXT) {
      break;
    }
  }

  if (uniqueTitles.length === 1) {
    return `Because you liked "${uniqueTitles[0]}"`;
  }

  return `Because you liked "${uniqueTitles.join('" and "')}"`;
}

function toRecommendation(movie, score, reason) {
  return {
    movieId: movie.id,
    title: movie.title,
    posterUrl: movie.poster_url,
    score:
      score === null
        ? null
        : Math.round(score * 100) / 100,
    reason,
  };
}

function buildRecommendationGroups(
  sourceMovies,
  candidates
) {
  return sourceMovies
    .slice(0, GROUP_SOURCE_LIMIT)
    .map(({ movie, vector }) => {
      const reason =
        `Because you liked "${movie.title}"`;

      const recommendations = candidates
        .map((candidate) => {
          const candidateVector =
            buildFeatureVector(candidate);

          const similarity =
            cosineSimilarity(
              vector,
              candidateVector
            );

          return {
            candidate,
            similarity,
          };
        })
        .sort((a, b) => {
          if (
            b.similarity !==
            a.similarity
          ) {
            return (
              b.similarity -
              a.similarity
            );
          }

          return a.candidate.title.localeCompare(
            b.candidate.title
          );
        })
        .slice(
          0,
          GROUP_MOVIES_LIMIT
        )
        .map(
          ({
            candidate,
            similarity,
          }) =>
            toRecommendation(
              candidate,
              similarity,
              reason
            )
        );

      return {
        sourceMovieId: movie.id,
        sourceTitle: movie.title,
        recommendations,
      };
    })
    .filter(
      (group) =>
        group.recommendations.length > 0
    );
}

async function getRecommendations(userId) {
  const ratingCount =
    await recommendationModel
      .getUserRatingCount(userId);

  // Cold start: until there are enough ratings,
  // show well-rated popular films.
  if (
    ratingCount <
    MIN_RATINGS_FOR_PERSONALIZATION
  ) {
    const popular =
      await recommendationModel
        .getPopularMovies(
          TOP_N_RECOMMENDATIONS
        );

    return {
      coldStart: true,

      ratingsNeeded:
        MIN_RATINGS_FOR_PERSONALIZATION -
        ratingCount,

      recommendations:
        popular.map((movie) =>
          toRecommendation(
            movie,
            null,
            'Popular with members'
          )
        ),

      groups: [],
    };
  }

  const highRatedMovies =
    await recommendationModel
      .getUserHighRatedMoviesWithFeatures(
        userId
      );

  const candidates =
    await recommendationModel
      .getCandidateMoviesWithFeatures(
        userId
      );

  // The member has enough ratings, but none
  // are strong positive signals.
  if (
    highRatedMovies.length === 0
  ) {
    const popular =
      await recommendationModel
        .getPopularMovies(
          TOP_N_RECOMMENDATIONS
        );

    return {
      coldStart: false,
      ratingsNeeded: 0,

      recommendations:
        popular.map((movie) =>
          toRecommendation(
            movie,
            null,
            'Popular with members'
          )
        ),

      groups: [],
    };
  }

  const ratedVectors =
    highRatedMovies.map(
      (movie) => ({
        movie,
        vector:
          buildFeatureVector(movie),
      })
    );

  // User profile:
  // a film rated 5 stars has a larger
  // influence than a film rated 4 stars.
  const userProfile =
    new Map();

  ratedVectors.forEach(
    ({ movie, vector }) => {
      addWeightedVector(
        userProfile,
        vector,
        movie.rating
      );
    }
  );

  const reasonSourceMovies = [
    ...ratedVectors,
  ]
    .sort((a, b) => {
      if (
        b.movie.rating !==
        a.movie.rating
      ) {
        return (
          b.movie.rating -
          a.movie.rating
        );
      }

      return a.movie.title.localeCompare(
        b.movie.title
      );
    })
    .slice(
      0,
      REASON_SOURCE_LIMIT
    );

  const scored =
    candidates.map(
      (candidate) => {
        const candidateVector =
          buildFeatureVector(
            candidate
          );

        const score =
          cosineSimilarity(
            userProfile,
            candidateVector
          );

        const topMatches =
          reasonSourceMovies
            .map(
              ({
                movie,
                vector,
              }) => ({
                movie,

                similarity:
                  cosineSimilarity(
                    vector,
                    candidateVector
                  ),
              })
            )
            .sort(
              (a, b) =>
                b.similarity -
                a.similarity
            )
            .slice(
              0,
              REASON_TOP_MATCHES
            );

        return toRecommendation(
          candidate,
          score,
          buildReasonText(
            topMatches
          )
        );
      }
    );

  scored.sort((a, b) => {
    if (b.score !== a.score) {
      return b.score - a.score;
    }

    return a.title.localeCompare(
      b.title
    );
  });

  const groupSources = [
    ...ratedVectors,
  ].sort((a, b) => {
    if (
      b.movie.rating !==
      a.movie.rating
    ) {
      return (
        b.movie.rating -
        a.movie.rating
      );
    }

    return a.movie.title.localeCompare(
      b.movie.title
    );
  });

  return {
    coldStart: false,
    ratingsNeeded: 0,

    recommendations:
      scored.slice(
        0,
        TOP_N_RECOMMENDATIONS
      ),

    groups:
      buildRecommendationGroups(
        groupSources,
        candidates
      ),
  };
}

module.exports = {
  getRecommendations,
};