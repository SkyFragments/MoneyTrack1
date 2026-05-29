const express = require('express');
const authMiddleware = require('../middleware/auth');
const { getDb, saveDbAsync } = require('../db');

const router = express.Router();

// Helper: add column if not exists
async function addColumnIfNotExists(db, column, type) {
  return new Promise((resolve) => {
    const stmt = db.prepare(`PRAGMA table_info(users)`);
    const columns = [];
    while (stmt.step()) {
      columns.push(stmt.getAsObject().name);
    }
    stmt.free();
    if (!columns.includes(column)) {
      db.run(`ALTER TABLE users ADD COLUMN ${column} ${type}`);
    }
    resolve();
  });
}

// GET /api/user/info — get user profile
router.get('/info', authMiddleware, async (req, res) => {
  try {
    const db = await getDb();
    await addColumnIfNotExists(db, 'avatar', 'TEXT');
    await addColumnIfNotExists(db, 'nickname', 'TEXT');
    await addColumnIfNotExists(db, 'gender', 'INTEGER DEFAULT 0');
    await addColumnIfNotExists(db, 'birth', 'TEXT');

    const stmt = db.prepare('SELECT id, username, email, phone, avatar, nickname, gender, birth, userType, createdAt FROM users WHERE id = ? AND deleted = 0');
    stmt.bind([req.userId]);
    stmt.step();
    const user = stmt.getAsObject();
    stmt.free();

    if (!user) {
      return res.status(404).json({ code: 404, msg: 'User not found' });
    }

    res.json({ code: 0, data: user });
  } catch (err) {
    res.status(500).json({ code: 500, msg: err.message });
  }
});

// PUT /api/user/info — update user profile
router.put('/info', authMiddleware, async (req, res) => {
  try {
    const { type, value } = req.body;
    if (!type || value === undefined) {
      return res.status(400).json({ code: 400, msg: 'type and value are required' });
    }

    const validTypes = ['avatar', 'nickname', 'name', 'gender', 'birth', 'phone'];
    if (!validTypes.includes(type)) {
      return res.status(400).json({ code: 400, msg: 'Invalid type' });
    }

    const db = await getDb();
    await addColumnIfNotExists(db, 'avatar', 'TEXT');
    await addColumnIfNotExists(db, 'nickname', 'TEXT');
    await addColumnIfNotExists(db, 'name', 'TEXT');
    await addColumnIfNotExists(db, 'gender', 'INTEGER DEFAULT 0');
    await addColumnIfNotExists(db, 'birth', 'TEXT');

    let columnName = type;
    let columnValue = value;

    // Map frontend UserInfoType to DB column names
    if (type === 'name') {
      columnName = 'username';
    }

    // Handle date conversion
    if (type === 'birth' && value instanceof Date) {
      columnValue = value.toISOString();
    } else if (type === 'birth' && typeof value === 'string') {
      columnValue = value;
    }

    const stmt = db.prepare(`UPDATE users SET ${columnName} = ?, updatedAt = datetime('now') WHERE id = ? AND deleted = 0`);
    stmt.run([columnValue, req.userId]);
    stmt.free();
    await saveDbAsync();

    res.json({ code: 0, data: { success: true } });
  } catch (err) {
    res.status(500).json({ code: 500, msg: err.message });
  }
});

// GET /api/user/membership — get membership info
router.get('/membership', authMiddleware, async (req, res) => {
  try {
    const db = await getDb();
    await addColumnIfNotExists(db, 'avatar', 'TEXT');
    await addColumnIfNotExists(db, 'nickname', 'TEXT');
    await addColumnIfNotExists(db, 'gender', 'INTEGER DEFAULT 0');
    await addColumnIfNotExists(db, 'birth', 'TEXT');

    const stmt = db.prepare('SELECT id, userType, createdAt FROM users WHERE id = ? AND deleted = 0');
    stmt.bind([req.userId]);
    stmt.step();
    const user = stmt.getAsObject();
    stmt.free();

    if (!user) {
      return res.status(404).json({ code: 404, msg: 'User not found' });
    }

    // Stub membership data — no real purchase tracking yet
    res.json({
      code: 0,
      data: {
        isSubscribed: false,
        expireDate: '',
        startDate: '',
      }
    });
  } catch (err) {
    res.status(500).json({ code: 500, msg: err.message });
  }
});

// POST /api/user/membership — subscribe (stub — no real IAP)
router.post('/membership', authMiddleware, async (req, res) => {
  // Real implementation would verify IAP receipt with Huawei IAP server
  // For now, accept the subscription without verifying
  res.json({ code: 0, data: { success: true, message: 'Membership activated' } });
});

// POST /api/user/login — username/password login (legacy path)
router.post('/login', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ code: 400, msg: 'Username and password are required' });
  }

  try {
    const bcrypt = require('bcryptjs');
    const db = await getDb();
    const stmt = db.prepare('SELECT id, username, email, password, createdAt FROM users WHERE (username = ? OR email = ?) AND deleted = 0');
    stmt.bind([username, username]);
    stmt.step();
    const user = stmt.getAsObject();
    stmt.free();

    if (!user || !user.password) {
      return res.status(401).json({ code: 401, msg: 'Invalid credentials' });
    }

    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) {
      return res.status(401).json({ code: 401, msg: 'Invalid credentials' });
    }

    const jwt = require('jsonwebtoken');
    const accessToken = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, { expiresIn: '2h' });
    const refreshToken = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, { expiresIn: '7d' });

    res.json({ code: 0, data: { user: { id: user.id, email: user.email }, accessToken, refreshToken } });
  } catch (err) {
    res.status(500).json({ code: 500, msg: err.message });
  }
});

// POST /api/user/logout — revoke tokens
router.post('/logout', authMiddleware, async (req, res) => {
  // Token revocation is handled by the auth middleware (tokens are not stored server-side for revocation)
  // Just acknowledge the logout
  res.json({ code: 0, data: { success: true } });
});

module.exports = router;