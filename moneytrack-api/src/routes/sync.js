const express = require('express');
const authMiddleware = require('../middleware/auth');
const syncService = require('../services/syncService');

const router = express.Router();

// GET /api/sync/pull?since={timestamp}
router.get('/pull', authMiddleware, async (req, res) => {
  if (req.userType === 'guest') {
    return res.status(403).json({ code: 403, msg: 'Guest accounts cannot sync to cloud' });
  }
  try {
    const since = parseInt(req.query.since, 10) || 0;
    const data = await syncService.pull(req.userId, since);
    res.json({ code: 0, data });
  } catch (err) {
    res.status(500).json({ code: 500, msg: err.message });
  }
});

// POST /api/sync/push
router.post('/push', authMiddleware, async (req, res) => {
  if (req.userType === 'guest') {
    return res.status(403).json({ code: 403, msg: 'Guest accounts cannot sync to cloud' });
  }
  try {
    const data = req.body;
    const counts = await syncService.push(req.userId, data);
    res.json({ code: 0, data: counts });
  } catch (err) {
    res.status(500).json({ code: 500, msg: err.message });
  }
});

module.exports = router;