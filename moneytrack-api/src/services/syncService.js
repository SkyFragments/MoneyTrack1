const { getDb, saveDbAsync } = require('../db');

const ALLOWED_TABLES = ['accounts', 'transactions', 'assets', 'budgets'];

function getLastInsertId(db) {
  const s = db.prepare('SELECT last_insert_rowid() as id');
  s.step();
  const id = s.getAsObject().id;
  s.free();
  return id;
}

/**
 * Pull: 获取服务端最新数据 (包含localId映射)
 * @param {string} userId - User ID
 * @param {number} [since=0] - Timestamp to fetch changes from
 * @returns {Promise<object>} - Object with table data arrays and serverTime
 */
async function pull(userId, since = 0) {
  if (!userId || typeof userId !== 'string') {
    throw new Error('Invalid userId');
  }

  let db;
  try {
    db = await getDb();
  } catch (err) {
    throw new Error('Failed to get database: ' + (err instanceof Error ? err.message : String(err)));
  }

  const sinceDate = new Date(since).toISOString();

  const result = {
    accounts: [],
    transactions: [],
    assets: [],
    budgets: [],
    categories: [],  // 预置分类也需要下发
    serverTime: Date.now(),
  };

  for (const table of ALLOWED_TABLES) {
    let selectCols = '*';
    if (table === 'accounts') selectCols = 'id AS accountId, userId, name, type, date, accountIncome, accountExpense, createdAt, updatedAt';
    else if (table === 'transactions') selectCols = 'id AS transactionId, userId, accountId, resource, type, amount, date, note, excluded, assetId, localId, createdAt, updatedAt';
    else if (table === 'assets') selectCols = 'id AS assetId, userId, name, type, subType, category, amount, note, isCustom, createdAt, updatedAt';
    else if (table === 'budgets') selectCols = 'id AS budgetId, userId, accountId, month, amount, createdAt, updatedAt';
    const stmt = db.prepare(`
      SELECT ${selectCols} FROM ${table}
      WHERE userId = ? AND updatedAt > ?
      ORDER BY id ASC
    `);
    stmt.bind([userId, sinceDate]);
    const rows = [];
    while (stmt.step()) rows.push(stmt.getAsObject());
    stmt.free();
    result[table] = rows;
  }

  // 下发预置分类 (isPreset=1)
  const catStmt = db.prepare('SELECT * FROM categories WHERE isPreset = 1 AND deleted = 0 ORDER BY key ASC');
  while (catStmt.step()) result.categories.push(catStmt.getAsObject());
  catStmt.free();

  return result;
}

/**
 * Push: 接收客户端数据, 服务端生成id覆盖localId
 * @param {string} userId - User ID
 * @param {object} data - Data object with accounts, transactions, assets, budgets arrays
 * @returns {Promise<{counts: object, mappings: Array<{table: string, localId: (string|number|null), serverId: number}>}>}
 */
async function push(userId, data) {
  if (!userId || typeof userId !== 'string') {
    throw new Error('Invalid userId');
  }

  if (!data || typeof data !== 'object') {
    throw new Error('Invalid data: expected object');
  }

  // Validate data structure - enforce ALLOWED_TABLES whitelist
  for (const table of ALLOWED_TABLES) {
    if (data[table] !== undefined && !Array.isArray(data[table])) {
      throw new Error(`Invalid data.${table}: expected array`);
    }
  }

  let db;
  try {
    db = await getDb();
  } catch (err) {
    throw new Error('Failed to get database: ' + (err instanceof Error ? err.message : String(err)));
  }

  const now = new Date().toISOString();
  const counts = { accounts: 0, transactions: 0, assets: 0, budgets: 0 };
  const mappings = [];

  // accounts
  for (const item of (data.accounts || [])) {
    if (!item || typeof item !== 'object') continue;
    if (item.deleted) {
      db.run('UPDATE accounts SET deleted = 1, updatedAt = ? WHERE id = ? AND userId = ?', [now, item.id, userId]);
    } else {
      const stmt = db.prepare(
        'INSERT INTO accounts (userId, name, type, date, accountIncome, accountExpense, createdAt, updatedAt, deleted) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0)'
      );
      stmt.run([userId, item.name, item.type || 'default', item.date || '01', item.accountIncome || 0, item.accountExpense || 0, now, now]);
      stmt.free();
      const serverId = getLastInsertId(db);
      counts.accounts++;
      if (item.id != null) {
        mappings.push({ table: 'accounts', localId: item.id, serverId });
      }
    }
  }

  // transactions: 保存localId, 服务端生成id
  for (const item of (data.transactions || [])) {
    if (!item || typeof item !== 'object') continue;
    // Validate resource is a valid INTEGER (not NaN, not string that parses to non-integer)
    const resource = Number(item.resource);
    if (isNaN(resource) || !Number.isInteger(resource)) continue;
    if (item.deleted) {
      db.run('UPDATE transactions SET deleted = 1, updatedAt = ? WHERE id = ? AND userId = ?', [now, item.id, userId]);
    } else {
      const stmt = db.prepare(`
        INSERT INTO transactions (userId, accountId, resource, type, amount, date, note, excluded, assetId, localId, createdAt, updatedAt, deleted)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
      `);
      stmt.run([
        userId, item.accountId, resource, item.type, item.amount, item.date,
        item.note || '', item.excluded ? 1 : 0, item.assetId || null, item.localId || null, now, now
      ]);
      stmt.free();
      const serverId = getLastInsertId(db);
      counts.transactions++;
      if (item.localId != null) {
        mappings.push({ table: 'transactions', localId: item.localId, serverId });
      }
    }
  }

  // assets
  for (const item of (data.assets || [])) {
    if (!item || typeof item !== 'object') continue;
    if (item.deleted) {
      db.run('UPDATE assets SET deleted = 1, updatedAt = ? WHERE id = ? AND userId = ?', [now, item.id, userId]);
    } else {
      const stmt = db.prepare(`
        INSERT INTO assets (userId, name, type, subType, category, amount, note, isCustom, createdAt, updatedAt, deleted)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
      `);
      stmt.run([userId, item.name, item.type, item.subType ?? 0, item.category ?? 1, item.amount ?? 0, item.note || '', item.isCustom ? 1 : 0, now, now]);
      stmt.free();
      const serverId = getLastInsertId(db);
      counts.assets++;
      if (item.id != null) {
        mappings.push({ table: 'assets', localId: item.id, serverId });
      }
    }
  }

  // budgets: upsert
  for (const item of (data.budgets || [])) {
    if (!item || typeof item !== 'object') continue;
    if (item.deleted) {
      db.run('UPDATE budgets SET deleted = 1, updatedAt = ? WHERE id = ? AND userId = ?', [now, item.id, userId]);
    } else {
      const check = db.prepare('SELECT id FROM budgets WHERE accountId = ? AND month = ? AND userId = ? AND deleted = 0');
      check.bind([item.accountId, item.month, userId]);
      if (check.step()) {
        check.free();
        db.run('UPDATE budgets SET amount = ?, updatedAt = ?, deleted = 0 WHERE accountId = ? AND month = ? AND userId = ? AND deleted = 0', [item.amount, now, item.accountId, item.month, userId]);
        counts.budgets++;
      } else {
        check.free();
        const stmt = db.prepare('INSERT INTO budgets (userId, accountId, month, amount, createdAt, updatedAt, deleted) VALUES (?, ?, ?, ?, ?, ?, 0)');
        stmt.run([userId, item.accountId, item.month, item.amount, now, now]);
        stmt.free();
        const lastIdStmt = db.prepare('SELECT last_insert_rowid() as id');
        lastIdStmt.step();
        const serverId = lastIdStmt.getAsObject().id;
        lastIdStmt.free();
        if (item.id != null) {
          mappings.push({ table: 'budgets', localId: item.id, serverId });
        }
        counts.budgets++;
      }
    }
  }

  await saveDbAsync();
  return { counts, mappings };
}

module.exports = { pull, push };
