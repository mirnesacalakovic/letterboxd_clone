const jwt = require("jsonwebtoken");

// Očekuje header: Authorization: Bearer <token>
// Ako je token validan, postavlja req.userId i propušta zahtev dalje.
// Inače vraća 401.
function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Nedostaje autentifikacioni token" });
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.userId;
    next();
  } catch (err) {
    return res.status(401).json({ error: "Nevažeći ili istekao token" });
  }
}

module.exports = authMiddleware;
