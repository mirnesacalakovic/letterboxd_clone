const recommendationModel = require('../models/recommendationModel');

const MIN_RATINGS_FOR_PERSONALIZATION = 5;
const TOP_N_RECOMMENDATIONS = 10;

// Za generisanje "reason" objašnjenja ne poredimo kandidata sa SVIM
// filmovima koje je korisnik ocenio ≥4.0 (moglo bi ih biti stotine) —
// ograničavamo se na njegovih top N najviše ocenjenih, da poređenje
// ostane brzo bez obzira koliko korisnik ima ocena ukupno.
const REASON_SOURCE_LIMIT = 20;
// Koliko sličnih filmova pamtimo po kandidatu (pre nego što izaberemo
// koliko od njih ide u tekst objašnjenja).
const REASON_TOP_MATCHES = 3;
// Koliko naslova stvarno ulazi u tekst objašnjenja korisniku.
const REASON_TITLES_IN_TEXT = 2;

// Težine po tipu feature-a — žanr je najjači signal ukusa, pa nosi
// najveću težinu; glumci/keywords su slabiji ali i dalje relevantni.
const WEIGHTS = {
  genre: 3,
  director: 2,
  actor: 1,
  keyword: 1,
};

// Pretvara film u "vreću tokena" — svaki token je prefiksovan tipom
// (npr. "genre:Drama", "actor:Tom Hanks") da se izbegnu kolizije
// (npr. glumac koji se preziva isto kao neki žanr ne postoji, ali
// prefiks čini kod robusnim i čitljivim za debug).
function buildFeatureVector(movie) {
  const vector = new Map();

  const addToken = (token, weight) => {
    if (!token) return;
    const key = token.toLowerCase().trim();
    if (!key) return;
    vector.set(key, (vector.get(key) || 0) + weight);
  };

  (movie.genres || []).forEach((g) => addToken(`genre:${g}`, WEIGHTS.genre));
  if (movie.director) addToken(`director:${movie.director}`, WEIGHTS.director);
  (movie.actors || []).forEach((a) => addToken(`actor:${a}`, WEIGHTS.actor));
  (movie.keywords || []).forEach((k) => addToken(`keyword:${k}`, WEIGHTS.keyword));

  return vector;
}

// Standardna cosine similarity nad dva sparse vektora (Map).
function cosineSimilarity(vecA, vecB) {
  const [smaller, larger] = vecA.size < vecB.size ? [vecA, vecB] : [vecB, vecA];

  let dotProduct = 0;
  for (const [key, valueA] of smaller) {
    const valueB = larger.get(key);
    if (valueB) dotProduct += valueA * valueB;
  }

  const magnitude = (vec) => Math.sqrt([...vec.values()].reduce((sum, v) => sum + v * v, 0));
  const magA = magnitude(vecA);
  const magB = magnitude(vecB);

  if (magA === 0 || magB === 0) return 0;
  return dotProduct / (magA * magB);
}

// Sabira dva vektora sa ponderom (koristi se za pravljenje profila
// korisnika iz više visoko ocenjenih filmova).
function addWeightedVector(target, source, weight) {
  for (const [key, value] of source) {
    target.set(key, (target.get(key) || 0) + value * weight);
  }
}

// Pravi tekst objašnjenja od liste najsličnijih filmova (već sortirane
// opadajuće po similarity). Rešava nekoliko edge case-ova:
// - manje matcheva nego što bismo želeli (korisnik ima malo ocena)
// - similarity 0 za sve (nema zajedničkog signala → generički tekst)
// - duplikati naslova (dva različita filma sa istim imenom u bazi)
function buildReasonText(topMatches) {
  const meaningfulMatches = topMatches.filter((m) => m.similarity > 0);

  if (meaningfulMatches.length === 0) {
    return 'Na osnovu tvog opšteg ukusa';
  }

  const uniqueTitles = [];
  for (const match of meaningfulMatches) {
    if (!uniqueTitles.includes(match.movie.title)) {
      uniqueTitles.push(match.movie.title);
    }
    if (uniqueTitles.length === REASON_TITLES_IN_TEXT) break;
  }

  if (uniqueTitles.length === 1) {
    return `Zato što ti se svideo film "${uniqueTitles[0]}"`;
  }
  return `Zato što ti se svideli filmovi "${uniqueTitles.join('" i "')}"`;
}

async function getRecommendations(userId) {
  const ratingCount = await recommendationModel.getUserRatingCount(userId);

  // --- Cold start: nema dovoljno podataka za pouzdan profil ---
  if (ratingCount < MIN_RATINGS_FOR_PERSONALIZATION) {
    const popular = await recommendationModel.getPopularMovies(TOP_N_RECOMMENDATIONS);
    return {
      coldStart: true,
      ratingsNeeded: MIN_RATINGS_FOR_PERSONALIZATION - ratingCount,
      recommendations: popular.map((m) => ({
        movieId: m.id,
        title: m.title,
        posterUrl: m.poster_url,
        score: null,
        reason: 'Popularan film među svim korisnicima',
      })),
    };
  }

  // --- Personalizovane preporuke ---
  const highRatedMovies = await recommendationModel.getUserHighRatedMoviesWithFeatures(userId);
  const candidates = await recommendationModel.getCandidateMoviesWithFeatures(userId);

  // Vektor svakog visoko ocenjenog filma, zapamćen posebno (ne samo
  // zbir) da bismo kasnije mogli da objasnimo ZAŠTO je nešto preporučeno.
  const ratedVectors = highRatedMovies.map((movie) => ({
    movie,
    vector: buildFeatureVector(movie),
  }));

  // Profil korisnika = zbir vektora ponderisan ocenom (viša ocena =
  // veći uticaj na profil).
  const userProfile = new Map();
  ratedVectors.forEach(({ movie, vector }) => {
    addWeightedVector(userProfile, vector, movie.rating);
  });

  // Za "reason" objašnjenje koristimo samo korisnikove top N najviše
  // ocenjenih filmova (ne sve) — edge case: ako korisnik ima npr. 200
  // ocena ≥4.0, ne želimo da poredimo svaki kandidat sa svih 200.
  const reasonSourceMovies = [...ratedVectors]
    .sort((a, b) => b.movie.rating - a.movie.rating)
    .slice(0, REASON_SOURCE_LIMIT);

  const scored = candidates.map((candidate) => {
    const candidateVector = buildFeatureVector(candidate);
    const score = cosineSimilarity(userProfile, candidateVector);

    // Sličnost sa svakim od "izvornih" filmova, zadržavamo top N —
    // ne samo jedan — da objašnjenje bude robusnije (npr. ako je top
    // film po similarity-ju slučajno "prazan" pogodak zbog retkog
    // zajedničkog tokena, imamo rezervu iz drugog i trećeg mesta).
    const allMatches = reasonSourceMovies.map(({ movie, vector }) => ({
      movie,
      similarity: cosineSimilarity(vector, candidateVector),
    }));
    allMatches.sort((a, b) => b.similarity - a.similarity);
    const topMatches = allMatches.slice(0, REASON_TOP_MATCHES);

    return {
      movieId: candidate.id,
      title: candidate.title,
      posterUrl: candidate.poster_url,
      score: Math.round(score * 100) / 100,
      reason: buildReasonText(topMatches),
    };
  });

  scored.sort((a, b) => b.score - a.score);

  return {
    coldStart: false,
    recommendations: scored.slice(0, TOP_N_RECOMMENDATIONS),
  };
}

module.exports = {
  getRecommendations,
};
