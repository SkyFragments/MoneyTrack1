const { getDb, saveDbAsync, getLastInsertId } = require('../db');

/**
 * Get all categories for a user (preset + custom)
 * @param {string} userId
 * @returns {Promise<Array>}
 */
async function getAll(userId) {
  const db = await getDb();
  const stmt = db.prepare(`
    SELECT * FROM categories
    WHERE deleted = 0 AND (isPreset = 1 OR userId = ?)
    ORDER BY isPreset DESC, sortOrder ASC
  `);
  stmt.bind([userId]);

  const results = [];
  while (stmt.step()) {
    results.push(stmt.getAsObject());
  }
  stmt.free();
  return results;
}

/**
 * Create a custom category for a user
 * @param {string} userId
 * @param {{ name: string, type: string, icon: string }} data
 * @returns {Promise<Object>}
 */
async function create(userId, data) {
  const db = await getDb();
  const now = new Date().toISOString();

  // Determine sortOrder for new category (max + 1 among user's custom categories)
  const sortStmt = db.prepare(`
    SELECT COALESCE(MAX(sortOrder), 0) + 1 as nextOrder
    FROM categories
    WHERE userId = ? AND isPreset = 0 AND deleted = 0
  `);
  sortStmt.bind([userId]);
  sortStmt.step();
  const sortResult = sortStmt.getAsObject();
  const sortOrder = sortResult?.nextOrder || 1;
  sortStmt.free();

  const stmt = db.prepare(`
    INSERT INTO categories (userId, name, type, icon, sortOrder, isPreset, createdAt, updatedAt, deleted)
    VALUES (?, ?, ?, ?, ?, 0, ?, ?, 0)
  `);
  stmt.run([userId, data.name, data.type, data.icon || '', sortOrder, now, now]);
  stmt.free();

  const serverId = getLastInsertId(db);
  await saveDbAsync();

  return { id: serverId, userId, name: data.name, type: data.type, icon: data.icon || '', sortOrder, isPreset: 0, createdAt: now, updatedAt: now, deleted: 0 };
}

/**
 * Update a custom category
 * @param {string} id
 * @param {string} userId
 * @param {{ name?: string, type?: string, icon?: string }} data
 * @returns {Promise<boolean>}
 */
async function update(id, userId, data) {
  const db = await getDb();

  // Check it's a custom category (not preset) and belongs to user
  const checkStmt = db.prepare(`
    SELECT id FROM categories WHERE id = ? AND userId = ? AND isPreset = 0 AND deleted = 0
  `);
  checkStmt.bind([id, userId]);

  if (!checkStmt.step()) {
    checkStmt.free();
    return false;
  }
  checkStmt.free();

  // Build update query dynamically
  const updates = [];
  const values = [];

  if (data.name !== undefined) {
    updates.push('name = ?');
    values.push(data.name);
  }
  if (data.type !== undefined) {
    updates.push('type = ?');
    values.push(data.type);
  }
  if (data.icon !== undefined) {
    updates.push('icon = ?');
    values.push(data.icon);
  }

  if (updates.length === 0) {
    return true;
  }

  updates.push('updatedAt = ?');
  values.push(new Date().toISOString());
  values.push(id);

  const sql = `UPDATE categories SET ${updates.join(', ')} WHERE id = ?`;
  const updateStmt = db.prepare(sql);
  updateStmt.bind(values);
  updateStmt.step();
  updateStmt.free();
  await saveDbAsync();

  return true;
}

/**
 * Soft delete a custom category
 * @param {string} id
 * @param {string} userId
 * @returns {Promise<boolean>}
 */
async function remove(id, userId) {
  const db = await getDb();

  // Only allow deleting custom categories (not preset) owned by user
  const checkStmt = db.prepare(`
    SELECT id FROM categories WHERE id = ? AND userId = ? AND isPreset = 0 AND deleted = 0
  `);
  checkStmt.bind([id, userId]);

  if (!checkStmt.step()) {
    checkStmt.free();
    return false;
  }
  checkStmt.free();

  const now = new Date().toISOString();
  db.run(`UPDATE categories SET deleted = 1, updatedAt = ? WHERE id = ?`, [now, id]);
  await saveDbAsync();

  return true;
}

module.exports = { getAll, create, update, remove };