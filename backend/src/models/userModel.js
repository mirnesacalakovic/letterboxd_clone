const pool = require('../config/db');

// Pronalazi korisnika po emailu (koristi se pri loginu i pri registraciji
// da se proveri da li email već postoji).
async function findByEmail(email) {
  const result = await pool.query(
    'SELECT * FROM users WHERE email = $1',
    [email]
  );
  return result.rows[0] || null;
}

// Pronalazi korisnika po username-u (koristi se pri registraciji da se
// proveri da li je username slobodan).
async function findByUsername(username) {
  const result = await pool.query(
    'SELECT * FROM users WHERE username = $1',
    [username]
  );
  return result.rows[0] || null;
}

// Pronalazi korisnika po id-u (koristi se u GET /api/auth/me i svuda
// gde treba dohvatiti trenutno ulogovanog korisnika).
async function findById(id) {
  const result = await pool.query(
    'SELECT id, username, email, avatar_url, bio, created_at FROM users WHERE id = $1',
    [id]
  );
  return result.rows[0] || null;
}

// Kreira novog korisnika. password_hash mora već biti hashovan
// (bcrypt) pre poziva ove funkcije — model ne zna ništa o hashovanju.
async function create({ username, email, passwordHash }) {
  const result = await pool.query(
    `INSERT INTO users (username, email, password_hash)
     VALUES ($1, $2, $3)
     RETURNING id, username, email, avatar_url, bio, created_at`,
    [username, email, passwordHash]
  );
  return result.rows[0];
}

// Profil korisnika sa agregiranim brojevima (watched, reviews, lists,
// followers, following) — koristi se za GET /api/users/:id.
async function findProfileById(id) {
  const result = await pool.query(
    `SELECT
       u.id, u.username, u.avatar_url, u.bio, u.created_at,
       (SELECT COUNT(*) FROM watched_movies WHERE user_id = u.id) AS watched_count,
       (SELECT COUNT(*) FROM reviews WHERE user_id = u.id) AS review_count,
       (SELECT COUNT(*) FROM movie_lists WHERE user_id = u.id) AS list_count,
       (SELECT COUNT(*) FROM follows WHERE following_id = u.id) AS followers_count,
       (SELECT COUNT(*) FROM follows WHERE follower_id = u.id) AS following_count
     FROM users u
     WHERE u.id = $1`,
    [id]
  );
  return result.rows[0] || null;
}

// Menja samo polja koja su prosleđena (partial update) — avatar_url i bio
// su opcioni po prirodi profila, username se retko menja ali dozvoljeno je.
async function update(id, { username, avatarUrl, bio }) {
  const result = await pool.query(
    `UPDATE users SET
       username = COALESCE($1, username),
       avatar_url = COALESCE($2, avatar_url),
       bio = COALESCE($3, bio)
     WHERE id = $4
     RETURNING id, username, email, avatar_url, bio, created_at, updated_at`,
    [username, avatarUrl, bio, id]
  );
  return result.rows[0];
}

// Pretraga korisnika po username-u (ILIKE, case-insensitive) —
// koristi se za GET /api/users/search?q=...
async function search(query, { limit = 20, offset = 0 }) {
  const likeQuery = `%${query}%`;
  const result = await pool.query(
    `SELECT id, username, avatar_url, bio
     FROM users
     WHERE username ILIKE $1
     ORDER BY username ASC
     LIMIT $2 OFFSET $3`,
    [likeQuery, limit, offset]
  );
  return result.rows;
}

module.exports = {
  findByEmail,
  findByUsername,
  findById,
  findProfileById,
  create,
  update,
  search,
};