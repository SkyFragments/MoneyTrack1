const { getDb, saveDb } = require('../db');

/**
 * Pull all changes since a given timestamp for a user
 * @param {string} userId
 * @param {number} since - Unix timestamp in milliseconds (default 0)
 * @returns {{ accounts: [], transactions: [], assets: [], budgets: [], serverTime: number }}
 */
async function pull(userId, since = 0) {
  const db = await getDb();
  const sinceDate = new Date(since).toISOString();

  const tables = ['accounts', 'transactions', 'assets', 'budgets'];
  const result = {
    accounts: [],
    transactions: [],
    assets: [],
    budgets: [],
    serverTime: Date.now(),
  };

  for (const table of tables) {
    const stmt = db.prepare(`
      SELECT * FROM ${table}
      WHERE userId = ? AND updatedAt > ?
      ORDER BY updatedAt ASC
    `);
    stmt.bind([userId, sinceDate]);

    const rows = [];
    while (stmt.step()) {
      rows.push(stmt.getAsObject());
    }
    stmt.free();
    result[table] = rows;
  }

  return result;
}

/**
 * Push local changes from client to server
 * @param {string} userId
 * @param {{ accounts: [], transactions: [], assets: [], budgets: [] }} data
 * @returns {{ accounts: number, transactions: number, assets: number, budgets: number }}
 */
async function push(userId, data) {
  const db = await getDb();
  const now = new Date().toISOString();

  const counts = { accounts: 0, transactions: 0, assets: 0, budgets: 0 };

  for (const table of ['accounts', 'transactions', 'assets', 'budgets']) {
    const items = data[table] || [];
    for (const item of items) {
      if (item.deleted) {
        // Soft delete
        const updateStmt = db.prepare(`
          UPDATE ${table} SET deleted = 1, updatedAt = ? WHERE id = ? AND userId = ?
        `);
        updateStmt.run([now, item.serverId || item.localId, userId]);
        updateStmt.free();
        counts[table]++;
      } else if (item.localId && !item.serverId) {
        // New item: INSERT with localId as id
        const columns = Object.keys(item).filter(k => k !== 'localId' && k !== 'serverId');
        const placeholders = columns.map(() => '?').join(', ');
        const values = columns.map(k => item[k]);

        const insertStmt = db.prepare(`
          INSERT INTO ${table} (id, ${columns.join(', ')}, createdAt, updatedAt)
          VALUES (?, ${placeholders}, ?, ?)
        `);
        insertStmt.run([item.localId, ...values, now, now]);
        insertStmt.free();
        counts[table]++;
      } else if (item.serverId) {
        // Update existing item
        const columns = Object.keys(item).filter(k => k !== 'localId' && k !== 'serverId' && k !== 'id');
        const setClause = columns.map(c => `${c} = ?`).join(', ');
        const values = columns.map(k => item[k]);

        const updateStmt = db.prepare(`
          UPDATE ${table} SET ${setClause}, updatedAt = ? WHERE id = ? AND userId = ?
        `);
        updateStmt.run([...values, now, item.serverId, userId]);
        updateStmt.free();
        counts[table]++;
      }
    }
    saveDb();
  }

  return counts;
}

module.exports = { pull, push };