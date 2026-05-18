const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const { getDb, saveDb } = require('../db');

const SALT_ROUNDS = 10;

async function createUser(email, password) {
  const db = await getDb();
  const id = uuidv4();
  const now = new Date().toISOString();
  const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);

  db.run(
    'INSERT INTO users (id, email, password, createdAt, updatedAt) VALUES (?, ?, ?, ?, ?)',
    [id, email, hashedPassword, now, now]
  );
  saveDb();

  return { id, email, createdAt: now };
}

async function validateUser(email, password) {
  const db = await getDb();
  const stmt = db.prepare('SELECT id, email, password, createdAt FROM users WHERE email = ?');
  const user = stmt.get([email]);
  stmt.free();

  if (!user) {
    return null;
  }

  const isValid = await bcrypt.compare(password, user.password);
  if (!isValid) {
    return null;
  }

  return { id: user.id, email: user.email, createdAt: user.createdAt };
}

async function findById(id) {
  const db = await getDb();
  const stmt = db.prepare('SELECT id, email, createdAt FROM users WHERE id = ?');
  const user = stmt.get([id]);
  stmt.free();

  return user;
}

async function findByHuaweiOpenId(openId) {
  const db = await getDb();
  const stmt = db.prepare('SELECT id, email, huaweiOpenId, createdAt FROM users WHERE huaweiOpenId = ?');
  const user = stmt.get([openId]);
  stmt.free();

  return user;
}

async function createFromHuawei(openId, email) {
  const db = await getDb();
  const id = uuidv4();
  const now = new Date().toISOString();

  db.run(
    'INSERT INTO users (id, email, huaweiOpenId, createdAt, updatedAt) VALUES (?, ?, ?, ?, ?)',
    [id, email, openId, now, now]
  );
  saveDb();

  return { id, email, huaweiOpenId: openId, createdAt: now };
}

module.exports = {
  createUser,
  validateUser,
  findById,
  findByHuaweiOpenId,
  createFromHuawei
};
