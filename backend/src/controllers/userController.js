const fs = require('node:fs/promises');
const path = require('node:path');
const crypto = require('node:crypto');

const userModel = require('../models/userModel');
const favoriteModel = require('../models/favoriteModel');

const MAX_FAVORITES = 4;

const AVATAR_DIR = path.join(
  __dirname,
  '..',
  '..',
  'uploads',
  'avatars'
);

// ============================================================
// PROFILE HELPERS
// ============================================================

function normalizeProfileData(body) {
  return {
    username:
      body.username === undefined
        ? undefined
        : String(body.username).trim(),

    bio:
      body.bio === undefined
        ? undefined
        : String(body.bio),
  };
}

function validateProfileData({ username, bio }) {
  if (username !== undefined && !username) {
    return 'Username ne može biti prazan';
  }

  if (
    username !== undefined &&
    username.length > 50
  ) {
    return 'Username može imati najviše 50 karaktera';
  }

  if (
    bio !== undefined &&
    bio.length > 1000
  ) {
    return 'Bio može imati najviše 1000 karaktera';
  }

  return null;
}

async function isUsernameTaken(username, userId) {
  if (username === undefined) {
    return false;
  }

  const existing =
    await userModel.findByUsername(username);

  if (!existing) {
    return false;
  }

  return String(existing.id) !== String(userId);
}

// ============================================================
// GET PROFILE
// GET /api/users/:id
// ============================================================

async function getProfile(req, res) {
  try {
    const [profile, favorites] =
      await Promise.all([
        userModel.findProfileById(
          req.params.id
        ),
        favoriteModel.findForUser(
          req.params.id
        ),
      ]);

    if (!profile) {
      return res.status(404).json({
        error: 'Korisnik ne postoji',
      });
    }

    res.json({
      user: {
        ...profile,
        favoriteMovies: favorites,
      },
    });
  } catch (err) {
    console.error(err);

    res.status(500).json({
      error: 'Internal Server Error',
    });
  }
}

// ============================================================
// UPDATE PROFILE
// PUT /api/users/:id
//
// Menja username i bio.
// Avatar se menja posebnim avatar endpointom.
// ============================================================

async function updateProfile(req, res) {
  try {
    if (
      String(req.params.id) !==
      String(req.userId)
    ) {
      return res.status(403).json({
        error:
          'Ne možeš menjati tuđi profil',
      });
    }

    const profileData =
      normalizeProfileData(req.body);

    const validationError =
      validateProfileData(profileData);

    if (validationError) {
      return res.status(400).json({
        error: validationError,
      });
    }

    const usernameTaken =
      await isUsernameTaken(
        profileData.username,
        req.userId
      );

    if (usernameTaken) {
      return res.status(409).json({
        error: 'Username je već zauzet',
      });
    }

    const updated =
      await userModel.update(
        req.userId,
        profileData
      );

    res.json({
      user: updated,
    });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({
        error: 'Username je već zauzet',
      });
    }

    console.error(err);

    res.status(500).json({
      error: 'Internal Server Error',
    });
  }
}

// ============================================================
// UPLOAD AVATAR
// POST /api/users/:id/avatar
//
// Prima pravi JPEG/PNG binary.
// ============================================================

async function uploadAvatar(req, res) {
  let newAbsolutePath = null;

  try {
    if (
      String(req.params.id) !==
      String(req.userId)
    ) {
      return res.status(403).json({
        error:
          'Ne možeš menjati tuđi avatar',
      });
    }

    if (
      !Buffer.isBuffer(req.body) ||
      req.body.length === 0
    ) {
      return res.status(400).json({
        error: 'Slika nije poslata',
      });
    }

    const contentType = String(
      req.headers['content-type'] || ''
    )
      .split(';')[0]
      .toLowerCase();

    if (
      ![
        'image/jpeg',
        'image/png',
      ].includes(contentType)
    ) {
      return res.status(415).json({
        error:
          'Avatar mora biti JPEG ili PNG slika',
      });
    }

    const currentUser =
      await userModel.findById(
        req.userId
      );

    if (!currentUser) {
      return res.status(404).json({
        error: 'Korisnik ne postoji',
      });
    }

    await fs.mkdir(
      AVATAR_DIR,
      {
        recursive: true,
      }
    );

    const extension =
      contentType === 'image/png'
        ? '.png'
        : '.jpg';

    const filename =
      `${req.userId}-${crypto.randomUUID()}${extension}`;

    newAbsolutePath = path.join(
      AVATAR_DIR,
      filename
    );

    await fs.writeFile(
      newAbsolutePath,
      req.body
    );

    const avatarUrl =
      `/uploads/avatars/${filename}`;

    const updated =
      await userModel.update(
        req.userId,
        {
          avatarUrl,
        }
      );

    if (
      currentUser.avatar_url?.startsWith(
        '/uploads/avatars/'
      )
    ) {
      const oldFilename =
        path.basename(
          currentUser.avatar_url
        );

      const oldAbsolutePath =
        path.join(
          AVATAR_DIR,
          oldFilename
        );

      if (
        oldAbsolutePath !==
        newAbsolutePath
      ) {
        await fs
          .unlink(oldAbsolutePath)
          .catch(() => {});
      }
    }

    res.json({
      user: updated,
    });
  } catch (err) {
    if (newAbsolutePath) {
      await fs
        .unlink(newAbsolutePath)
        .catch(() => {});
    }

    console.error(err);

    res.status(500).json({
      error: 'Internal Server Error',
    });
  }
}

// ============================================================
// FAVORITES
// PUT /api/users/:id/favorites
// ============================================================

async function setFavorites(req, res) {
  try {
    if (
      String(req.params.id) !==
      String(req.userId)
    ) {
      return res.status(403).json({
        error:
          'Ne možeš menjati tuđe omiljene filmove',
      });
    }

    const { movieIds } = req.body;

    if (!Array.isArray(movieIds)) {
      return res.status(400).json({
        error:
          'movieIds mora biti niz ID-jeva filmova',
      });
    }

    if (
      movieIds.length >
      MAX_FAVORITES
    ) {
      return res.status(400).json({
        error:
          `Maksimalno ${MAX_FAVORITES} omiljena filma`,
      });
    }

    const uniqueIds =
      new Set(movieIds);

    if (
      uniqueIds.size !==
      movieIds.length
    ) {
      return res.status(400).json({
        error:
          'Isti film ne može biti dodat dvaput',
      });
    }

    const favorites =
      await favoriteModel.setForUser(
        req.userId,
        movieIds
      );

    res.json({
      favoriteMovies: favorites,
    });
  } catch (err) {
    if (err.code === '23503') {
      return res.status(400).json({
        error:
          'Jedan ili više movieId ne postoje',
      });
    }

    console.error(err);

    res.status(500).json({
      error: 'Internal Server Error',
    });
  }
}

// ============================================================
// SEARCH USERS
// GET /api/users/search?q=...
// ============================================================

async function searchUsers(req, res) {
  try {
    const query = req.query.q;

    if (
      !query?.trim()
    ) {
      return res.status(400).json({
        error:
          'Query parametar q je obavezan',
      });
    }

    const limit =
      Number.parseInt(
        req.query.limit,
        10
      ) || 20;

    const offset =
      Number.parseInt(
        req.query.offset,
        10
      ) || 0;

    const users =
      await userModel.search(
        query.trim(),
        {
          limit,
          offset,
        }
      );

    res.json({
      users,
    });
  } catch (err) {
    console.error(err);

    res.status(500).json({
      error: 'Internal Server Error',
    });
  }
}

module.exports = {
  getProfile,
  updateProfile,
  uploadAvatar,
  setFavorites,
  searchUsers,
};