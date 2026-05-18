const express = require('express');
const jwt = require('jsonwebtoken');
const userService = require('../services/userService');
const authMiddleware = require('../middleware/auth');

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
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ code: 400, msg: 'Email and password are required' });
    }

    const user = await userService.createUser(email, password);
    const { accessToken, refreshToken } = generateTokens(user.id);

    res.json({ code: 0, data: { user, accessToken, refreshToken } });
  } catch (err) {
    res.status(400).json({ code: 400, msg: err.message });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  const user = await userService.validateUser(email, password);
  if (!user) {
    return res.status(401).json({ code: 401, msg: 'Invalid credentials' });
  }

  const { accessToken, refreshToken } = generateTokens(user.id);

  res.json({ code: 0, data: { user, accessToken, refreshToken } });
});

// POST /api/auth/refresh
router.post('/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({ code: 400, msg: 'Refresh token is required' });
    }

    const decoded = jwt.verify(refreshToken, process.env.JWT_SECRET);
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
