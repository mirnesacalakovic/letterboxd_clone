require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const pool = require('./config/db');

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '100kb' }));

// Opšti rate limit — 200 zahteva po IP adresi na 15 minuta, za sve rute.
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  message: { error: 'Previše zahteva. Pokušaj ponovo kasnije.' },
});
app.use(generalLimiter);

// Stroži limit samo za login/register — sprečava brute-force pokušaje
// pogađanja lozinke (5 pokušaja na 15 minuta po IP adresi).
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: { error: 'Previše pokušaja prijave. Pokušaj ponovo za 15 minuta.' },
});

// Health check — potvrđuje da server radi i da je konekcija na bazu uspešna
app.get('/api/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', database: 'connected' });
  } catch (err) {
    console.error('Health check greška:', err);
    res.status(500).json({ status: 'error', database: 'disconnected' });
  }
});

// Ovde ćemo kasnije dodavati nove rute (movies, ratings, itd.)
const authRoutes = require('./routes/authRoutes');
app.use('/api/auth', authLimiter, authRoutes);

const movieRoutes = require('./routes/movieRoutes');
app.use('/api/movies', movieRoutes);

const ratingRoutes = require('./routes/ratingRoutes');
app.use('/api/ratings', ratingRoutes);

const watchedRoutes = require('./routes/watchedRoutes');
app.use('/api/watched', watchedRoutes);

const watchlistRoutes = require('./routes/watchlistRoutes');
app.use('/api/watchlist', watchlistRoutes);

const reviewRoutes = require('./routes/reviewRoutes');
app.use('/api/reviews', reviewRoutes);

const userRoutes = require('./routes/userRoutes');
app.use('/api/users', userRoutes);

const feedRoutes = require('./routes/feedRoutes');
app.use('/api/feed', feedRoutes);

const listRoutes = require('./routes/listRoutes');
app.use('/api/lists', listRoutes);

const recommendationRoutes = require('./routes/recommendationRoutes');
app.use('/api/recommendations', recommendationRoutes);

const homeRoutes = require('./routes/homeRoutes');
app.use('/api/home', homeRoutes);

const statsRoutes = require('./routes/statsRoutes');
app.use('/api/stats', statsRoutes);

const commentRoutes = require('./routes/commentRoutes');
app.use('/api/comments', commentRoutes);

const diaryRoutes = require('./routes/diaryRoutes');
app.use('/api/diary', diaryRoutes);

// 404 handler za nepostojeće rute
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Globalni error handler — hvata sve greške koje eksplicitno ne obradiš
// u kontrolerima, da server nikad ne padne zbog neuhvaćenog izuzetka.
// MORA biti poslednji app.use() poziv.
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal Server Error' });
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server pokrenut na http://localhost:${PORT}`);
});