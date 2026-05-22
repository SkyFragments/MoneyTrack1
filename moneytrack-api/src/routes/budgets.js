const express = require('express');
const { getDb, saveDbAsync, getLastInsertId } = require('../db');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// GET /api/budgets
router.get('/', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const { accountId, month } = req.query;
    const db = await getDb();

    let sql = 'SELECT * FROM budgets WHERE userId = ? AND deleted = 0';
    const params = [userId];
    if (accountId) { sql += ' AND accountId = ?'; params.push(accountId); }
    if (month) { sql += ' AND month = ?'; params.push(month); }
    sql += ' ORDER BY month ASC';

    const stmt = db.prepare(sql);
    stmt.bind(params);
    const rows = [];
    while (stmt.step()) rows.push(stmt.getAsObject());
    stmt.free();
    res.json({ code: 0, data: rows });
  } catch (err) {
    res.status(500).json({ code: 500, msg: err.message });
  }
});

// POST /api/budgets
router.post('/', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const { accountId, month, amount } = req.body;
    if (!accountId || !month || amount === undefined) return res.status(400).json({ code: 400, msg: 'accountId, month, amount required' });

    const db = await getDb();
    const now = new Date().toISOString();

    // Upsert by accountId+month
    const check = db.prepare('SELECT id FROM budgets WHERE accountId = ? AND month = ? AND userId = ? AND deleted = 0');
    check.bind([accountId, month, userId]);
    if (check.step()) {
      const existingId = check.getAsObject().id;
      check.free();
      db.run('UPDATE budgets SET amount = ?, updatedAt = ?, deleted = 0 WHERE id = ?', [amount, now, existingId]);
      await saveDbAsync();
      return res.json({ code: 0, data: { id: existingId, accountId, month, amount } });
    }
    check.free();

    const stmt = db.prepare(
      'INSERT INTO budgets (userId, accountId, month, amount, createdAt, updatedAt, deleted) VALUES (?, ?, ?, ?, ?, ?, 0)'
    );
    stmt.run([userId, accountId, month, amount, now, now]);
    stmt.free();

    const serverId = getLastInsertId(db);

    await saveDbAsync();
    res.json({ code: 0, data: { id: serverId, accountId, month, amount } });
  } catch (err) {
    res.status(400).json({ code: 400, msg: err.message });
  }
});

// PUT /api/budgets/:id
router.put('/:id', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const { amount } = req.body;
    const db = await getDb();
    const now = new Date().toISOString();

    const check = db.prepare('SELECT id FROM budgets WHERE id = ? AND userId = ? AND deleted = 0');
    check.bind([req.params.id, userId]);
    if (!check.step()) { check.free(); return res.status(404).json({ code: 404, msg: 'not found' }); }
    check.free();

    const updateStmt = db.prepare('UPDATE budgets SET amount = ?, updatedAt = ? WHERE id = ?');
    updateStmt.bind([amount, now, req.params.id]);
    updateStmt.step();
    updateStmt.free();

    await saveDbAsync();
    res.json({ code: 0, data: true });
  } catch (err) {
    res.status(400).json({ code: 400, msg: err.message });
  }
});

// DELETE /api/budgets/:id
router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const db = await getDb();
    const now = new Date().toISOString();

    const check = db.prepare('SELECT id FROM budgets WHERE id = ? AND userId = ? AND deleted = 0');
    check.bind([req.params.id, userId]);
    if (!check.step()) { check.free(); return res.status(404).json({ code: 404, msg: 'not found' }); }
    check.free();

    db.run('UPDATE budgets SET deleted = 1, updatedAt = ? WHERE id = ?', [now, req.params.id]);
    await saveDbAsync();
    res.json({ code: 0, data: true });
  } catch (err) {
    res.status(400).json({ code: 400, msg: err.message });
  }
});

module.exports = router;
