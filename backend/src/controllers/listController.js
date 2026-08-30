const listModel = require('../models/listModel');

// POST /api/lists
async function create(req, res) {
  try {
    const { name, description, isPublic } = req.body;
    if (!name || !name.trim()) {
      return res.status(400).json({ error: 'name je obavezan' });
    }

    const list = await listModel.create({ userId: req.userId, name: name.trim(), description, isPublic });
    res.status(201).json({ list });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// GET /api/lists — vraća SVOJE liste (privatne i javne) trenutnog korisnika.
// Za tuđe javne liste koristi se GET /api/users/:id (profil), koji bi
// kasnije mogao linkovati na ovu listu preko user_id filtera po potrebi.
async function getAllForCurrentUser(req, res) {
  try {
    const lists = await listModel.findAllForUser(req.userId, { includePrivate: true });
    res.json({ lists });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// GET /api/lists/:id — javno ako je is_public, inače samo vlasnik.
// authMiddleware NIJE na ovoj ruti (mora da radi i bez tokena za javne
// liste), pa proveravamo req.userId koji može biti undefined.
async function getById(req, res) {
  try {
    const list = await listModel.findById(req.params.id);
    if (!list) {
      return res.status(404).json({ error: 'Lista ne postoji' });
    }
    if (!list.is_public && list.user_id !== req.userId) {
      return res.status(403).json({ error: 'Ova lista je privatna' });
    }

    const movies = await listModel.findMoviesInList(list.id);
    res.json({ list: { ...list, movies } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// PUT /api/lists/:id — samo vlasnik.
async function update(req, res) {
  try {
    const existing = await listModel.findById(req.params.id);
    if (!existing) {
      return res.status(404).json({ error: 'Lista ne postoji' });
    }
    if (existing.user_id !== req.userId) {
      return res.status(403).json({ error: 'Nemaš pravo da menjaš tuđu listu' });
    }

    const { name, description, isPublic } = req.body;
    const updated = await listModel.update(req.params.id, { name, description, isPublic });
    res.json({ list: updated });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// DELETE /api/lists/:id — samo vlasnik.
async function remove(req, res) {
  try {
    const existing = await listModel.findById(req.params.id);
    if (!existing) {
      return res.status(404).json({ error: 'Lista ne postoji' });
    }
    if (existing.user_id !== req.userId) {
      return res.status(403).json({ error: 'Nemaš pravo da brišeš tuđu listu' });
    }

    await listModel.remove(req.params.id);
    res.json({ message: 'Lista obrisana' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// POST /api/lists/:id/movies/:movieId — samo vlasnik dodaje filmove.
async function addMovie(req, res) {
  try {
    const { id, movieId } = req.params;

    const list = await listModel.findById(id);
    if (!list) {
      return res.status(404).json({ error: 'Lista ne postoji' });
    }
    if (list.user_id !== req.userId) {
      return res.status(403).json({ error: 'Nemaš pravo da menjaš tuđu listu' });
    }

    const existing = await listModel.findMovieInList(id, movieId);
    if (existing) {
      return res.status(409).json({ error: 'Film je već u ovoj listi' });
    }

    const position = await listModel.getNextPosition(id);
    const entry = await listModel.addMovie(id, movieId, position);
    res.status(201).json({ entry });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// DELETE /api/lists/:id/movies/:movieId — samo vlasnik.
async function removeMovie(req, res) {
  try {
    const { id, movieId } = req.params;

    const list = await listModel.findById(id);
    if (!list) {
      return res.status(404).json({ error: 'Lista ne postoji' });
    }
    if (list.user_id !== req.userId) {
      return res.status(403).json({ error: 'Nemaš pravo da menjaš tuđu listu' });
    }

    const existing = await listModel.findMovieInList(id, movieId);
    if (!existing) {
      return res.status(404).json({ error: 'Film nije u ovoj listi' });
    }

    await listModel.removeMovie(id, movieId);
    res.json({ message: 'Film uklonjen iz liste' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// GET /api/lists/discover — javno, ne zahteva login. Sve javne liste
// svih korisnika, za otkrivanje novog sadržaja.
async function discover(req, res) {
  try {
    const limit = parseInt(req.query.limit, 10) || 20;
    const offset = parseInt(req.query.offset, 10) || 0;
    const sortBy = req.query.sortBy === 'movieCount' ? 'movieCount' : 'newest';

    const lists = await listModel.findAllPublic({ limit, offset, sortBy });
    res.json({ lists });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

module.exports = {
  create,
  getAllForCurrentUser,
  getById,
  update,
  remove,
  addMovie,
  removeMovie,
  discover,
};
