const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const { getDb, saveDbAsync } = require('../db');

const SALT_ROUNDS = 10;

async function createUser(username, password, email = null) {
  const db = await getDb();
  const id = uuidv4();
  const now = new Date().toISOString();
  const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);

  const stmt = db.prepare(
    'INSERT INTO users (id, username, email, password, userType, createdAt, updatedAt) VALUES (?, ?, ?, ?, ?, ?, ?)'
  );
  stmt.run([id, username, email, hashedPassword, 'full', now, now]);
  stmt.free();
  await saveDbAsync();

  return { id, username, email, createdAt: now };
}

async function validateUser(usernameOrEmail, password) {
  const db = await getDb();
  const stmt = db.prepare(
    'SELECT id, username, email, password, createdAt FROM users WHERE (username = ? OR email = ?) AND deleted = 0'
  );
  stmt.bind([usernameOrEmail, usernameOrEmail]);
  stmt.step();
  const user = stmt.getAsObject();
  stmt.free();

  if (!user || !user.password) {
    return null;
  }

  const isValid = await bcrypt.compare(password, user.password);
  if (!isValid) {
    return null;
  }

  return { id: user.id, username: user.username, email: user.email, createdAt: user.createdAt };
}

async function findById(id) {
  const db = await getDb();
  const stmt = db.prepare('SELECT id, username, email, userType, createdAt FROM users WHERE id = ? AND deleted = 0');
  stmt.bind([id]);
  stmt.step();
  const user = stmt.getAsObject();
  stmt.free();

  return user;
}

async function findByHuaweiOpenId(openId) {
  const db = await getDb();
  const stmt = db.prepare('SELECT id, email, huaweiOpenId, createdAt FROM users WHERE huaweiOpenId = ? AND deleted = 0');
  stmt.bind([openId]);
  stmt.step();
  const user = stmt.getAsObject();
  stmt.free();

  return user;
}

async function findByPhone(phone) {
  const db = await getDb();
  const stmt = db.prepare('SELECT id, phone, userType, createdAt FROM users WHERE phone = ? AND deleted = 0');
  stmt.bind([phone]);
  stmt.step();
  const user = stmt.getAsObject();
  stmt.free();

  return user;
}

async function createUserFromPhone(phone) {
  const db = await getDb();
  const id = uuidv4();
  const now = new Date().toISOString();

  const stmt = db.prepare(
    'INSERT INTO users (id, phone, userType, createdAt, updatedAt) VALUES (?, ?, ?, ?, ?)'
  );
  stmt.run([id, phone, 'full', now, now]);
  stmt.free();
  await saveDbAsync();

  return { id, phone, userType: 'full', createdAt: now };
}

async function createFromHuawei(openId, email) {
  const db = await getDb();
  const id = uuidv4();
  const now = new Date().toISOString();

  const stmt = db.prepare(
    'INSERT INTO users (id, email, huaweiOpenId, createdAt, updatedAt) VALUES (?, ?, ?, ?, ?)'
  );
  stmt.run([id, email, openId, now, now]);
  stmt.free();
  await saveDbAsync();

  return { id, email, huaweiOpenId: openId, userType: 'full', createdAt: now };
}

async function createGuestUser() {
  const db = await getDb();
  const id = uuidv4();
  const now = new Date().toISOString();
  const username = 'guest_' + id.slice(0, 8);

  const stmt = db.prepare(
    'INSERT INTO users (id, username, userType, createdAt, updatedAt) VALUES (?, ?, ?, ?, ?)'
  );
  stmt.run([id, username, 'guest', now, now]);
  stmt.free();
  await saveDbAsync();

  return { id, username, userType: 'guest', createdAt: now };
}

async function upgradeGuestUser(userId, username, password) {
  const db = await getDb();
  const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);
  const now = new Date().toISOString();

  const stmt = db.prepare(
    'UPDATE users SET username = ?, password = ?, userType = ?, updatedAt = ? WHERE id = ? AND deleted = 0'
  );
  stmt.run([username, hashedPassword, 'full', now, userId]);
  stmt.free();
  await saveDbAsync();

  return await findById(userId);
}

module.exports = {
  createUser,
  validateUser,
  findById,
  findByHuaweiOpenId,
  findByPhone,
  createFromHuawei,
  createUserFromPhone,
  createGuestUser,
  upgradeGuestUser
};
