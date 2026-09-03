require('dotenv').config();

const express =
  require('express');

const cors =
  require('cors');

const helmet =
  require('helmet');

const rateLimit =
  require('express-rate-limit');

const path =
  require('node:path');

const pool =
  require('./config/db');

const app = express();

app.use(helmet());
app.use(cors());

app.use(
  '/uploads',
  express.static(
    path.join(
      __dirname,
      '..',
      'uploads'
    )
  )
);

app.use(
  express.json({
    limit: '100kb',
  })
);

const generalLimiter =
  rateLimit({
    windowMs:
      15 * 60 * 1000,

    max: 200,

    message: {
      error:
        'Previše zahteva. Pokušaj ponovo kasnije.',
    },
  });

app.use(generalLimiter);

const authLimiter =
  rateLimit({
    windowMs:
      15 * 60 * 1000,

    max: 5,

    message: {
      error:
        'Previše pokušaja prijave. Pokušaj ponovo za 15 minuta.',
    },
  });

app.get(
  '/api/health',
  async (req, res) => {
    try {
      await pool.query(
        'SELECT 1'
      );

      res.json({
        status: 'ok',
        database: 'connected',
      });
    } catch (err) {
      console.error(
        'Health check greška:',
        err
      );

      res.status(500).json({
        status: 'error',
        database:
          'disconnected',
      });
    }
  }
);

const authRoutes =
  require('./routes/authRoutes');

app.use(
  '/api/auth',
  authLimiter,
  authRoutes
);

const movieRoutes =
  require('./routes/movieRoutes');

app.use(
  '/api/movies',
  movieRoutes
);

const ratingRoutes =
  require('./routes/ratingRoutes');

app.use(
  '/api/ratings',
  ratingRoutes
);

const watchedRoutes =
  require('./routes/watchedRoutes');

app.use(
  '/api/watched',
  watchedRoutes
);

const watchlistRoutes =
  require('./routes/watchlistRoutes');

app.use(
  '/api/watchlist',
  watchlistRoutes
);

const reviewRoutes =
  require('./routes/reviewRoutes');

app.use(
  '/api/reviews',
  reviewRoutes
);

const userRoutes =
  require('./routes/userRoutes');

app.use(
  '/api/users',
  userRoutes
);

const feedRoutes =
  require('./routes/feedRoutes');

app.use(
  '/api/feed',
  feedRoutes
);

const listRoutes =
  require('./routes/listRoutes');

app.use(
  '/api/lists',
  listRoutes
);

const recommendationRoutes =
  require(
    './routes/recommendationRoutes'
  );

app.use(
  '/api/recommendations',
  recommendationRoutes
);

const homeRoutes =
  require('./routes/homeRoutes');

app.use(
  '/api/home',
  homeRoutes
);

const statsRoutes =
  require('./routes/statsRoutes');

app.use(
  '/api/stats',
  statsRoutes
);

const commentRoutes =
  require('./routes/commentRoutes');

app.use(
  '/api/comments',
  commentRoutes
);

const diaryRoutes =
  require('./routes/diaryRoutes');

app.use(
  '/api/diary',
  diaryRoutes
);

// Novi kompletni Letterboxd Log flow.
const logRoutes =
  require('./routes/logRoutes');

app.use(
  '/api/log',
  logRoutes
);

app.use(
  (req, res) => {
    res.status(404).json({
      error:
        'Route not found',
    });
  }
);

app.use(
  (err, req, res, next) => {
    if (
      err?.type === 'entity.too.large'
    ) {
      return res.status(413).json({
        error:
          'Slika je prevelika. Maksimalno 5 MB.',
      });
    }

    console.error(err.stack);

    return res.status(500).json({
      error:
        'Internal Server Error',
    });
  }
);

const PORT =
  process.env.PORT || 3000;

app.listen(
  PORT,
  () => {
    console.log(
      `Server pokrenut na http://localhost:${PORT}`
    );
  }
);