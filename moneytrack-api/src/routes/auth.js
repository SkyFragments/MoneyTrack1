const express = require('express');
const jwt = require('jsonwebtoken');
const userService = require('../services/userService');
const authMiddleware = require('../middleware/auth');
const { revokeToken, isTokenRevoked } = require('../db');

const router = express.Router();

const JWT_ACCESS_EXPIRES = process.env.JWT_ACCESS_EXPIRES || '2h';
const JWT_REFRESH_EXPIRES = process.env.JWT_REFRESH_EXPIRES || '7d';

/**
 * Generate access and refresh tokens for a user
 * @param {string} userId
 * @returns {{ accessToken: string, refreshToken: string }}
 */
function generateTokens(userId) {
  const accessToken = jwt.sign(
    { userId },
    process.env.JWT_SECRET,
    { expiresIn: JWT_ACCESS_EXPIRES }
  );
  const refreshToken = jwt.sign(
    { userId },
    process.env.JWT_SECRET,
    { expiresIn: JWT_REFRESH_EXPIRES }
  );
  return { accessToken, refreshToken };
}

// POST /api/auth/register
router.post('/register', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ code: 400, msg: 'Username and password are required' });
    }

    if (typeof username !== 'string' || username.length < 3 || username.length > 30) {
      return res.status(400).json({ code: 400, msg: 'Username must be 3-30 characters' });
    }

    if (typeof password !== 'string' || password.length < 6) {
      return res.status(400).json({ code: 400, msg: 'Password must be at least 6 characters' });
    }

    const user = await userService.createUser(username, password);
    const { accessToken, refreshToken } = generateTokens(user.id);

    res.json({ code: 0, data: { user, accessToken, refreshToken } });
  } catch (err) {
    if (err.message.includes('UNIQUE')) {
      return res.status(400).json({ code: 400, msg: 'Username already exists' });
    }
    res.status(400).json({ code: 400, msg: err.message });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ code: 400, msg: 'Username and password are required' });
  }

  const user = await userService.validateUser(username, password);
  if (!user) {
    return res.status(401).json({ code: 401, msg: 'Invalid credentials' });
  }

  const { accessToken, refreshToken } = generateTokens(user.id);

  res.json({ code: 0, data: { user, accessToken, refreshToken } });
});

// POST /api/auth/phone-login/send — send verification code
router.post('/phone-login/send', async (req, res) => {
  const { phoneNumber } = req.body;

  if (!phoneNumber || typeof phoneNumber !== 'string' || phoneNumber.length !== 11) {
    return res.status(400).json({ code: 400, msg: 'Invalid phone number' });
  }

  const code = Math.floor(100000 + Math.random() * 900000).toString();
  const db = await getDb();
  const stmt = db.prepare(
    'INSERT OR REPLACE INTO verify_codes (phone, code, expiresAt, deleted) VALUES (?, ?, datetime("now", "+5 minutes"), 0)'
  );
  stmt.run([phoneNumber, code]);
  stmt.free();
  await saveDbAsync();

  console.log(`[DEV] SMS code for ${phoneNumber}: ${code}`);
  res.json({ code: 0, data: { message: 'Verification code sent' } });
});

// POST /api/auth/phone-login — verify code and login
router.post('/phone-login', async (req, res) => {
  const { phoneNumber, code } = req.body;

  if (!phoneNumber || !code) {
    return res.status(400).json({ code: 400, msg: 'Phone number and code are required' });
  }

  const db = await getDb();
  const stmt = db.prepare('SELECT * FROM verify_codes WHERE phone = ? AND code = ? AND expiresAt > datetime("now") AND deleted = 0');
  stmt.bind([phoneNumber, code]);
  stmt.step();
  const record = stmt.getAsObject();
  stmt.free();

  if (!record || !record.phone) {
    return res.status(401).json({ code: 401, msg: 'Invalid or expired verification code' });
  }

  const delStmt = db.prepare('UPDATE verify_codes SET deleted = 1 WHERE id = ?');
  delStmt.run([record.id]);
  delStmt.free();
  await saveDbAsync();

  let user = await userService.findByPhone(phoneNumber);
  if (!user) {
    user = await userService.createUserFromPhone(phoneNumber);
  }

  const { accessToken, refreshToken } = generateTokens(user.id);
  res.json({ code: 0, data: { user, accessToken, refreshToken } });
});

// POST /api/auth/huawei-login
router.post('/huawei-login', async (req, res) => {
  try {
    const { openId, email } = req.body;

    if (!openId) {
      return res.status(400).json({ code: 400, msg: 'openId is required' });
    }

    let user = await userService.findByHuaweiOpenId(openId);
    if (!user) {
      if (!email) {
        return res.status(400).json({ code: 400, msg: 'email required for new user' });
      }
      user = await userService.createFromHuawei(openId, email);
    }

    const { accessToken, refreshToken } = generateTokens(user.id);
    res.json({ code: 0, data: { user, accessToken, refreshToken } });
  } catch (err) {
    res.status(500).json({ code: 500, msg: err.message });
  }
});

// POST /api/auth/refresh
router.post('/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({ code: 400, msg: 'Refresh token is required' });
    }

    const decoded = jwt.verify(refreshToken, process.env.JWT_SECRET);
    if (isTokenRevoked(refreshToken)) {
      return res.status(401).json({ code: 401, msg: 'Token has been revoked' });
    }
    revokeToken(refreshToken);
    const { accessToken, refreshToken: newRefreshToken } = generateTokens(decoded.userId);

    res.json({ code: 0, data: { accessToken, refreshToken: newRefreshToken } });
  } catch (err) {
    res.status(401).json({ code: 401, msg: 'Invalid or expired refresh token' });
  }
});

// GET /api/auth/me
router.get('/me', authMiddleware, async (req, res) => {
  const user = await userService.findById(req.userId);

  if (!user) {
    return res.status(404).json({ code: 404, msg: 'User not found' });
  }

  res.json({ code: 0, data: user });
});

// POST /api/auth/upgrade
router.post('/upgrade', authMiddleware, async (req, res) => {
  const { username, password } = req.body;

  if (req.userType !== 'guest') {
    return res.status(400).json({ code: 400, msg: 'User is not a guest' });
  }

  if (!username || !password) {
    return res.status(400).json({ code: 400, msg: 'Username and password are required' });
  }

  if (typeof username !== 'string' || username.length < 3 || username.length > 30) {
    return res.status(400).json({ code: 400, msg: 'Username must be 3-30 characters' });
  }

  if (typeof password !== 'string' || password.length < 6) {
    return res.status(400).json({ code: 400, msg: 'Password must be at least 6 characters' });
  }

  try {
    const user = await userService.upgradeGuestUser(req.userId, username, password);
    const { accessToken, refreshToken } = generateTokens(user.id);
    res.json({ code: 0, data: { user, accessToken, refreshToken } });
  } catch (err) {
    if (err.message.includes('UNIQUE')) {
      return res.status(400).json({ code: 400, msg: 'Username already exists' });
    }
    res.status(400).json({ code: 400, msg: err.message });
  }
});

module.exports = router;
