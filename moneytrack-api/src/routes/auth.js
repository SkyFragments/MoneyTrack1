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

module.exports = router;
