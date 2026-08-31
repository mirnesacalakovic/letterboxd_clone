// Zajednička logika za content-based similarity (žanr/režiser/glumci/
// keywords vektori + cosine similarity), izdvojena iz
// recommendationService.js da je koristi i similarMoviesService.js
// bez dupliranja koda.

// Težine po tipu feature-a — žanr je najjači signal, pa nosi najveću
// težinu; glumci/keywords su slabiji ali i dalje relevantni.
const WEIGHTS = {
  genre: 3,
  director: 2,
  actor: 1,
  keyword: 1,
};

// Pretvara film u "vreću tokena" — svaki token je prefiksovan tipom
// (npr. "genre:Drama", "actor:Tom Hanks") da se izbegnu kolizije.
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

module.exports = {
  buildFeatureVector,
  cosineSimilarity,
  addWeightedVector,
};
