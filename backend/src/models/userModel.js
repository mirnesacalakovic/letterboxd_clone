const pool = require("../config/db");

// Pronalazi korisnika po emailu (koristi se pri loginu i pri registraciji
// da se proveri da li email već postoji).
async function findByEmail(email) {
  const result = await pool.query("SELECT * FROM users WHERE email = $1", [
    email,
  ]);
  return result.rows[0] || null;
}

// Pronalazi korisnika po username-u (koristi se pri registraciji da se
// proveri da li je username slobodan).
async function findByUsername(username) {
  const result = await pool.query("SELECT * FROM users WHERE username = $1", [
    username,
  ]);
  return result.rows[0] || null;
}

// Pronalazi korisnika po id-u (koristi se u GET /api/auth/me i svuda
// gde treba dohvatiti trenutno ulogovanog korisnika).
async function findById(id) {
  const result = await pool.query(
    "SELECT id, username, email, avatar_url, bio, created_at FROM users WHERE id = $1",
    [id],
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
    [username, email, passwordHash],
  );
  return result.rows[0];
}

module.exports = {
  findByEmail,
  findByUsername,
  findById,
  create,
};
