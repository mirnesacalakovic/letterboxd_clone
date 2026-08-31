const recommendationModel = require('../models/recommendationModel');
const { buildFeatureVector, cosineSimilarity } = require('./similarityUtils');

const TOP_N_SIMILAR = 10;

// Za razliku od recommendationService (profil korisnika naspram svih
// filmova), ovo je jednostavnije: JEDAN film naspram svih ostalih.
// Koristi se na Movie Details ekranu ("Filmovi slični ovom"), nezavisno
// od toga da li je korisnik uopšte ulogovan ili ima ikakve ocene.
async function getSimilarMovies(movieId) {
  const targetMovie = await recommendationModel.getMovieFeatures(movieId);
  if (!targetMovie) {
    return null;
  }

  const candidates = await recommendationModel.getAllMovieFeaturesExcept(movieId);
  const targetVector = buildFeatureVector(targetMovie);

  const scored = candidates.map((candidate) => {
    const candidateVector = buildFeatureVector(candidate);
    const score = cosineSimilarity(targetVector, candidateVector);
    return {
      movieId: candidate.id,
      title: candidate.title,
      posterUrl: candidate.poster_url,
      score: Math.round(score * 100) / 100,
    };
  });

  // Filtriramo score=0 (nema NIKAKVOG zajedničkog signala) — bolje
  // vratiti manje od 10 rezultata nego potpuno nepovezane filmove.
  const meaningful = scored.filter((m) => m.score > 0);
  meaningful.sort((a, b) => b.score - a.score);

  return meaningful.slice(0, TOP_N_SIMILAR);
}

module.exports = {
  getSimilarMovies,
};