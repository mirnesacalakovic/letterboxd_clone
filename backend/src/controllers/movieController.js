const movieModel = require('../models/movieModel');
const reviewModel = require('../models/reviewModel');
const movieLikeModel = require('../models/movieLikeModel');
const similarMoviesService = require('../services/similarMoviesService');

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

    const { movies, total } = await movieModel.findAll({ limit, offset, decade, minRating, sortBy });
    res.json({ movies, total });
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
    const { movies, total } = await movieModel.search(query.trim(), { limit, offset });
    res.json({ movies, total });
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
    const sortBy = req.query.sortBy === 'mostLiked' ? 'mostLiked' : 'newest';
    const reviews = await reviewModel.findAllForMovie(req.params.id, { sortBy });
    res.json({ reviews });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// POST /api/movies/:id/like — lajk na SAM film (odvojeno od review likes).
async function likeMovie(req, res) {
  try {
    const movie = await movieModel.findById(req.params.id);
    if (!movie) {
      return res.status(404).json({ error: 'Film ne postoji' });
    }

    const existing = await movieLikeModel.findByUserAndMovie(req.userId, req.params.id);
    if (existing) {
      return res.status(409).json({ error: 'Već si lajkovala ovaj film' });
    }

    const like = await movieLikeModel.likeMovie(req.userId, req.params.id);
    res.status(201).json({ like });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// DELETE /api/movies/:id/like
async function unlikeMovie(req, res) {
  try {
    const existing = await movieLikeModel.findByUserAndMovie(req.userId, req.params.id);
    if (!existing) {
      return res.status(404).json({ error: 'Nisi lajkovala ovaj film' });
    }

    await movieLikeModel.unlikeMovie(req.userId, req.params.id);
    res.json({ message: 'Lajk uklonjen' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// GET /api/movies/:id/similar — javno, movie-to-movie cosine similarity.
async function getSimilar(req, res) {
  try {
    const similar = await similarMoviesService.getSimilarMovies(req.params.id);
    if (similar === null) {
      return res.status(404).json({ error: 'Film ne postoji' });
    }
    res.json({ similar });
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
  likeMovie,
  unlikeMovie,
  getSimilar,
};