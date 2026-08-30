const jwt = require('jsonwebtoken');

// Za rute koje rade i bez logina (javni sadržaj), ali se ponašaju
// drugačije ako je korisnik ipak ulogovan (npr. da vidi svoju privatnu
// listu). Za razliku od authMiddleware, ovaj NIKAD ne vraća 401 —
// samo ostavlja req.userId kao undefined ako nema validnog tokena.
function optionalAuthMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next();
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.userId;
  } catch (err) {
    // Nevažeći token se ignoriše — tretiramo zahtev kao anoniman.
  }
  next();
}

module.exports = optionalAuthMiddleware;
