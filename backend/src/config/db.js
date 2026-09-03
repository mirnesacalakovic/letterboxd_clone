const { Pool, types } = require('pg');

types.setTypeParser(20, (value) => Number.parseInt(value, 10));
types.setTypeParser(1700, (value) => Number.parseFloat(value));

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