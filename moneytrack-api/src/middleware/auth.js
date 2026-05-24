const jwt = require('jsonwebtoken');
const userService = require('../services/userService');

/**
 * JWT Bearer token authentication middleware
 */
async function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return res.status(401).json({ code: 401, msg: 'No token provided' });
  }

  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') {
    return res.status(401).json({ code: 401, msg: 'No token provided' });
  }

  const token = parts[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.userId;

    const user = await userService.findById(decoded.userId);
    if (!user) {
      return res.status(401).json({ code: 401, msg: 'User not found or deleted' });
    }
    req.userType = user.userType || 'full';

    next();
  } catch (err) {
    return res.status(401).json({ code: 401, msg: 'Invalid or expired token' });
  }
}

module.exports = authMiddleware;
