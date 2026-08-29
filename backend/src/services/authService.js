const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const userModel = require("../models/userModel");

const SALT_ROUNDS = 10;

// Generiše JWT token za datog korisnika. Token ističe za 7 dana —
// za mobilnu aplikaciju je uobičajeno duže trajanje nego za web.
function generateToken(user) {
  return jwt.sign({ userId: user.id }, process.env.JWT_SECRET, {
    expiresIn: "7d",
  });
}

// Registruje novog korisnika. Baca grešku sa .statusCode ako username
// ili email već postoje — kontroler tu grešku pretvara u HTTP odgovor.
async function register({ username, email, password }) {
  const existingEmail = await userModel.findByEmail(email);
  if (existingEmail) {
    const err = new Error("Email already in use");
    err.statusCode = 409;
    throw err;
  }

  const existingUsername = await userModel.findByUsername(username);
  if (existingUsername) {
    const err = new Error("Username already taken");
    err.statusCode = 409;
    throw err;
  }

  const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
  const user = await userModel.create({ username, email, passwordHash });
  const token = generateToken(user);

  return { user, token };
}

// Prijavljuje korisnika. Baca grešku sa .statusCode 401 ako email
// ne postoji ili lozinka ne odgovara — namerno ista poruka za oba
// slučaja, da se ne otkriva da li email postoji u bazi.
async function login({ email, password }) {
  const userWithHash = await userModel.findByEmail(email);
  if (!userWithHash) {
    const err = new Error("Invalid email or password");
    err.statusCode = 401;
    throw err;
  }

  const passwordMatches = await bcrypt.compare(
    password,
    userWithHash.password_hash,
  );
  if (!passwordMatches) {
    const err = new Error("Invalid email or password");
    err.statusCode = 401;
    throw err;
  }

  const token = generateToken(userWithHash);

  // Ne vraćamo password_hash nazad klijentu
  const { password_hash, ...user } = userWithHash;

  return { user, token };
}

module.exports = {
  register,
  login,
  generateToken,
};
