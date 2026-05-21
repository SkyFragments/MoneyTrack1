const express = require('express');
const { getDb, saveDbAsync } = require('../db');

const router = express.Router();

// GET /api/transactions
router.get('/', async (req, res) => {
  try {
    const userId = req.userId;
    const { accountId, since } = req.query;
    const db = await getDb();

    let sql = 'SELECT id AS transactionId, userId, accountId, resource, type, amount, date, note, excluded, assetId, localId, createdAt, updatedAt FROM transactions WHERE userId = ? AND deleted = 0';
    const params = [userId];
    if (accountId) { sql += ' AND accountId = ?'; params.push(accountId); }
    if (since) { sql += ' AND updatedAt > ?'; params.push(new Date(parseInt(since)).toISOString()); }
    sql += ' ORDER BY date DESC, transactionId DESC';

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

// POST /api/transactions
router.post('/', async (req, res) => {
  try {
    const userId = req.userId;
    const { localId, accountId, resource, type, amount, date, note, excluded, assetId } = req.body;
    if (!accountId || !resource || !type || !amount || !date) {
      return res.status(400).json({ code: 400, msg: 'accountId, resource, type, amount, date required' });
    }

    const db = await getDb();
    const now = new Date().toISOString();

    const stmt = db.prepare(`
      INSERT INTO transactions (userId, accountId, resource, type, amount, date, note, excluded, assetId, localId, createdAt, updatedAt, deleted)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
    `);
    stmt.run([userId, accountId, resource, type, amount, date, note || '', excluded ? 1 : 0, assetId || null, localId || null, now, now]);
    stmt.free();

    const idResult = db.exec('SELECT last_insert_rowid() as id');
    const serverId = idResult[0].values[0][0];

    // Update account income/expense
    const field = type === 'income' ? 'accountIncome' : 'accountExpense';
    db.run(`UPDATE accounts SET ${field} = ${field} + ? WHERE id = ?`, [amount, accountId]);

    await saveDbAsync();
    res.json({ code: 0, data: { transactionId: serverId, localId, resource, type, amount, date, note, excluded, assetId } });
  } catch (err) {
    res.status(400).json({ code: 400, msg: err.message });
  }
});

// PUT /api/transactions/:id
router.put('/:id', async (req, res) => {
  try {
    const userId = req.userId;
    const { accountId, resource, type, amount, date, note, excluded, assetId } = req.body;
    const db = await getDb();
    const now = new Date().toISOString();

    const check = db.prepare('SELECT * FROM transactions WHERE id = ? AND userId = ? AND deleted = 0');
    check.bind([req.params.id, userId]);
    if (!check.step()) { check.free(); return res.status(404).json({ code: 404, msg: 'not found' }); }
    const old = check.getAsObject();
    check.free();

    const updates = [];
    const values = [];
    const fieldValues = { accountId, resource, type, amount, date, note, excluded, assetId };
    const fields = ['accountId','resource','type','amount','date','note','excluded','assetId'];
    for (const f of fields) {
      if (fieldValues[f] !== undefined) { updates.push(f + ' = ?'); values.push(fieldValues[f]); }
    }
    updates.push('updatedAt = ?');
    values.push(now);
    values.push(req.params.id);

    db.run(`UPDATE transactions SET ${updates.join(', ')} WHERE id = ?`, values);

    // Reverse old account totals
    if (old.type && old.amount && old.amount > 0) {
      const origField = old.type === 'income' ? 'accountIncome' : 'accountExpense';
      db.run(`UPDATE accounts SET ${origField} = ${origField} - ? WHERE id = ?`, [old.amount, old.accountId]);
    }
    if (type && amount && amount > 0) {
      const newField = type === 'income' ? 'accountIncome' : 'accountExpense';
      db.run(`UPDATE accounts SET ${newField} = ${newField} + ? WHERE id = ?`, [amount, accountId || old.accountId]);
    }

    await saveDbAsync();
    res.json({ code: 0, data: true });
  } catch (err) {
    res.status(400).json({ code: 400, msg: err.message });
  }
});

// DELETE /api/transactions/:id
router.delete('/:id', async (req, res) => {
  try {
    const userId = req.userId;
    const db = await getDb();
    const now = new Date().toISOString();

    const check = db.prepare('SELECT * FROM transactions WHERE id = ? AND userId = ? AND deleted = 0');
    check.bind([req.params.id, userId]);
    if (!check.step()) { check.free(); return res.status(404).json({ code: 404, msg: 'not found' }); }
    const old = check.getAsObject();
    check.free();

    db.run('UPDATE transactions SET deleted = 1, updatedAt = ? WHERE id = ?', [now, req.params.id]);

    if (old.type && old.amount) {
      const field = old.type === 'income' ? 'accountIncome' : 'accountExpense';
      db.run(`UPDATE accounts SET ${field} = ${field} - ? WHERE id = ?`, [old.amount, old.accountId]);
    }
    await saveDbAsync();
    res.json({ code: 0, data: true });
  } catch (err) {
    res.status(400).json({ code: 400, msg: err.message });
  }
});

module.exports = router;
