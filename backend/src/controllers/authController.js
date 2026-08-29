const authService = require("../services/authService");
const userModel = require("../models/userModel");

async function register(req, res) {
  try {
    const { username, email, password } = req.body;

    if (!username || !email || !password) {
      return res
        .status(400)
        .json({ error: "username, email i password su obavezni" });
    }
    if (password.length < 6) {
      return res
        .status(400)
        .json({ error: "Lozinka mora imati bar 6 karaktera" });
    }

    const { user, token } = await authService.register({
      username,
      email,
      password,
    });
    res.status(201).json({ user, token });
  } catch (err) {
    res
      .status(err.statusCode || 500)
      .json({ error: err.message || "Internal Server Error" });
  }
}

async function login(req, res) {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: "email i password su obavezni" });
    }

    const { user, token } = await authService.login({ email, password });
    res.json({ user, token });
  } catch (err) {
    res
      .status(err.statusCode || 500)
      .json({ error: err.message || "Internal Server Error" });
  }
}

// req.userId postavlja authMiddleware nakon provere JWT-a
async function me(req, res) {
  try {
    const user = await userModel.findById(req.userId);
    if (!user) {
      return res.status(404).json({ error: "Korisnik ne postoji" });
    }
    res.json({ user });
  } catch (err) {
    res.status(500).json({ error: "Internal Server Error" });
  }
}

// JWT je stateless, pa server ne mora ništa da čuva — logout se
// svodi na to da klijent obriše token lokalno. Endpoint postoji
// radi konzistentnosti API-ja sa specifikacijom.
async function logout(req, res) {
  res.json({ message: "Uspešno odjavljen" });
}

module.exports = {
  register,
  login,
  me,
  logout,
};
