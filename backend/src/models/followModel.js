const pool = require('../config/db');

async function findFollow(followerId, followingId) {
  const result = await pool.query(
    'SELECT * FROM follows WHERE follower_id = $1 AND following_id = $2',
    [followerId, followingId]
  );
  return result.rows[0] || null;
}

async function follow(followerId, followingId) {
  const result = await pool.query(
    `INSERT INTO follows (follower_id, following_id)
     VALUES ($1, $2)
     RETURNING *`,
    [followerId, followingId]
  );
  return result.rows[0];
}

async function unfollow(followerId, followingId) {
  await pool.query(
    'DELETE FROM follows WHERE follower_id = $1 AND following_id = $2',
    [followerId, followingId]
  );
}

// Lista korisnika koji prate datog korisnika.
async function findFollowers(userId) {
  const result = await pool.query(
    `SELECT u.id, u.username, u.avatar_url, u.bio
     FROM follows f
     JOIN users u ON u.id = f.follower_id
     WHERE f.following_id = $1
     ORDER BY f.created_at DESC`,
    [userId]
  );
  return result.rows;
}

// Lista korisnika koje dati korisnik prati.
async function findFollowing(userId) {
  const result = await pool.query(
    `SELECT u.id, u.username, u.avatar_url, u.bio
     FROM follows f
     JOIN users u ON u.id = f.following_id
     WHERE f.follower_id = $1
     ORDER BY f.created_at DESC`,
    [userId]
  );
  return result.rows;
}

module.exports = {
  findFollow,
  follow,
  unfollow,
  findFollowers,
  findFollowing,
};