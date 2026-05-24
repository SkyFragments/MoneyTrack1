const express = require('express');
const jwt = require('jsonwebtoken');
const userService = require('../services/userService');

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

// POST /api/guest/create — create guest account
router.post('/create', async (req, res) => {
  try {
    const guest = await userService.createGuestUser();
    const { accessToken, refreshToken } = generateTokens(guest.id);
    res.json({ code: 0, data: { user: guest, accessToken, refreshToken } });
  } catch (err) {
    res.status(500).json({ code: 500, msg: err.message });
  }
});

module.exports = router;