const express = require('express');
const { getDb, saveDbAsync } = require('../db');

const router = express.Router();

// GET /api/assets
router.get('/', async (req, res) => {
  try {
    const userId = req.userId;
    const db = await getDb();
    const stmt = db.prepare('SELECT id AS assetId, userId, name, type, subType, category, amount, note, isCustom, createdAt, updatedAt FROM assets WHERE userId = ? AND deleted = 0 ORDER BY assetId ASC');
    stmt.bind([userId]);
    const rows = [];
    while (stmt.step()) rows.push(stmt.getAsObject());
    stmt.free();
    res.json({ code: 0, data: rows });
  } catch (err) {
    res.status(500).json({ code: 500, msg: err.message });
  }
});

// POST /api/assets
router.post('/', async (req, res) => {
  try {
    const userId = req.userId;
    const { name, type, subType, category, amount, note } = req.body;
    if (!name || type === undefined) return res.status(400).json({ code: 400, msg: 'name and type required' });

    const db = await getDb();
    const now = new Date().toISOString();

    const stmt = db.prepare(
      'INSERT INTO assets (userId, name, type, subType, category, amount, note, isCustom, createdAt, updatedAt, deleted) VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?, ?, 0)'
    );
    stmt.run([userId, name, type, subType ?? 0, category ?? 1, amount ?? 0, note || '', now, now]);
    stmt.free();

    const idResult = db.exec('SELECT last_insert_rowid() as id');
    const serverId = idResult[0].values[0][0];

    await saveDbAsync();
    res.json({ code: 0, data: { assetId: serverId, name, type, subType: subType ?? 0, category: category ?? 1, amount: amount ?? 0, note: note || '', isCustom: 0 } });
  } catch (err) {
    res.status(400).json({ code: 400, msg: err.message });
  }
});

// PUT /api/assets/:id
router.put('/:id', async (req, res) => {
  try {
    const userId = req.userId;
    const db = await getDb();
    const now = new Date().toISOString();

    const check = db.prepare('SELECT id FROM assets WHERE id = ? AND userId = ? AND deleted = 0');
    check.bind([req.params.id, userId]);
    if (!check.step()) { check.free(); return res.status(404).json({ code: 404, msg: 'not found' }); }
    check.free();

    const updates = [];
    const values = [];
    const fields = ['name','type','subType','category','amount','note'];
    for (const f of fields) {
      if (req.body[f] !== undefined) { updates.push(f + ' = ?'); values.push(req.body[f]); }
    }
    updates.push('updatedAt = ?');
    values.push(now);
    values.push(req.params.id);

    db.run(`UPDATE assets SET ${updates.join(', ')} WHERE id = ?`, values);
    await saveDbAsync();
    res.json({ code: 0, data: true });
  } catch (err) {
    res.status(400).json({ code: 400, msg: err.message });
  }
});

// DELETE /api/assets/:id
router.delete('/:id', async (req, res) => {
  try {
    const userId = req.userId;
    const db = await getDb();
    const now = new Date().toISOString();

    const check = db.prepare('SELECT id FROM assets WHERE id = ? AND userId = ? AND deleted = 0');
    check.bind([req.params.id, userId]);
    if (!check.step()) { check.free(); return res.status(404).json({ code: 404, msg: 'not found' }); }
    check.free();

    db.run('UPDATE assets SET deleted = 1, updatedAt = ? WHERE id = ?', [now, req.params.id]);
    await saveDbAsync();
    res.json({ code: 0, data: true });
  } catch (err) {
    res.status(400).json({ code: 400, msg: err.message });
  }
});

module.exports = router;