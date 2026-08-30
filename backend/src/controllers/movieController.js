const movieModel = require('../models/movieModel');
const reviewModel = require('../models/reviewModel');

async function getAll(req, res) {
  try {
    const limit = parseInt(req.query.limit, 10) || 20;
    const offset = parseInt(req.query.offset, 10) || 0;

    const decade = req.query.decade ? parseInt(req.query.decade, 10) : undefined;
    if (decade !== undefined && (isNaN(decade) || decade % 10 !== 0)) {
      return res.status(400).json({ error: 'decade mora biti broj deljiv sa 10, npr. 1990' });
    }

    const minRating = req.query.minRating ? parseFloat(req.query.minRating) : undefined;
    if (minRating !== undefined && (isNaN(minRating) || minRating < 0.5 || minRating > 5.0)) {
      return res.status(400).json({ error: 'minRating mora biti između 0.5 i 5.0' });
    }

    const sortBy = ['newest', 'rating', 'popular', 'title'].includes(req.query.sortBy) ? req.query.sortBy : 'title';

    const movies = await movieModel.findAll({ limit, offset, decade, minRating, sortBy });
    res.json({ movies });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

async function getById(req, res) {
  try {
    const movie = await movieModel.findById(req.params.id);
    if (!movie) {
      return res.status(404).json({ error: 'Film ne postoji' });
    }
    res.json({ movie });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

async function searchMovies(req, res) {
  try {
    const query = req.query.q;
    if (!query || !query.trim()) {
      return res.status(400).json({ error: 'Query parametar q je obavezan' });
    }
    const limit = parseInt(req.query.limit, 10) || 20;
    const offset = parseInt(req.query.offset, 10) || 0;
    const movies = await movieModel.search(query.trim(), { limit, offset });
    res.json({ movies });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

async function getReviews(req, res) {
  try {
    const movie = await movieModel.findById(req.params.id);
    if (!movie) {
      return res.status(404).json({ error: 'Film ne postoji' });
    }
    const reviews = await reviewModel.findAllForMovie(req.params.id);
    res.json({ reviews });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

module.exports = {
  getAll,
  getById,
  searchMovies,
  getReviews,
};