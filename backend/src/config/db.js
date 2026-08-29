const { Pool } = require('pg');

// Jedina konekcija na bazu u celoj aplikaciji.
// Svi drugi fajlovi (modeli, kontroleri) importuju ovaj pool.
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

pool.on('connect', () => {
  console.log('Povezano na PostgreSQL bazu');
});

pool.on('error', (err) => {
  console.error('Neočekivana greška na PostgreSQL konekciji:', err);
  process.exit(-1);
});

module.exports = pool;