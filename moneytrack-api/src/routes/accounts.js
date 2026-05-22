const express = require('express');
const { getDb, saveDbAsync, getLastInsertId } = require('../db');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// GET /api/accounts
router.get('/', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const db = await getDb();
    const stmt = db.prepare('SELECT id AS accountId, userId, name, type, date, accountIncome, accountExpense, createdAt, updatedAt FROM accounts WHERE userId = ? AND deleted = 0 ORDER BY accountId ASC');
    stmt.bind([userId]);
    const accounts = [];
    while (stmt.step()) accounts.push(stmt.getAsObject());
    stmt.free();
    res.json({ code: 0, data: accounts });
  } catch (err) {
    res.status(500).json({ code: 500, msg: err.message });
  }
});

// POST /api/accounts
router.post('/', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const { name, type, date } = req.body;
    if (!name) return res.status(400).json({ code: 400, msg: 'name required' });

    const db = await getDb();
    const now = new Date().toISOString();

    const stmt = db.prepare(
      'INSERT INTO accounts (userId, name, type, date, accountIncome, accountExpense, createdAt, updatedAt, deleted) VALUES (?, ?, ?, ?, 0, 0, ?, ?, 0)'
    );
    stmt.run([userId, name, type || 'default', date || '01', now, now]);
    stmt.free();

    const serverId = getLastInsertId(db);

    await saveDbAsync();
    res.json({ code: 0, data: { accountId: serverId, name, type: type || 'default', date: date || '01', accountIncome: 0, accountExpense: 0 } });
  } catch (err) {
    res.status(400).json({ code: 400, msg: err.message });
  }
});

// PUT /api/accounts/:id
router.put('/:id', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const { name, type, date } = req.body;
    const db = await getDb();
    const now = new Date().toISOString();

    const check = db.prepare('SELECT id FROM accounts WHERE id = ? AND userId = ? AND deleted = 0');
    check.bind([req.params.id, userId]);
    if (!check.step()) { check.free(); return res.status(404).json({ code: 404, msg: 'not found' }); }
    check.free();

    const updates = [];
    const values = [];
    if (name !== undefined) { updates.push('name = ?'); values.push(name); }
    if (type !== undefined) { updates.push('type = ?'); values.push(type); }
    if (date !== undefined) { updates.push('date = ?'); values.push(date); }
    updates.push('updatedAt = ?');
    values.push(now);
    values.push(req.params.id);

    const sql = `UPDATE accounts SET ${updates.join(', ')} WHERE id = ?`;
    const updateStmt = db.prepare(sql);
    updateStmt.bind(values);
    updateStmt.step();
    updateStmt.free();

    await saveDbAsync();
    res.json({ code: 0, data: true });
  } catch (err) {
    res.status(400).json({ code: 400, msg: err.message });
  }
});

// DELETE /api/accounts/:id
router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const db = await getDb();
    const now = new Date().toISOString();

    const check = db.prepare('SELECT id FROM accounts WHERE id = ? AND userId = ? AND deleted = 0');
    check.bind([req.params.id, userId]);
    if (!check.step()) { check.free(); return res.status(404).json({ code: 404, msg: 'not found' }); }
    check.free();

    db.run('UPDATE accounts SET deleted = 1, updatedAt = ? WHERE id = ?', [now, req.params.id]);
    await saveDbAsync();
    res.json({ code: 0, data: true });
  } catch (err) {
    res.status(400).json({ code: 400, msg: err.message });
  }
});

module.exports = router;