const { v4: uuidv4 } = require('uuid');
const { getDb, saveDb } = require('../db');

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
  const maxOrderResult = db.exec(`
    SELECT COALESCE(MAX(sortOrder), 0) + 1 as nextOrder
    FROM categories
    WHERE userId = '${userId}' AND isPreset = 0 AND deleted = 0
  `);
  const sortOrder = maxOrderResult.length > 0 ? maxOrderResult[0].values[0][0] : 1;

  const category = {
    id: uuidv4(),
    userId,
    name: data.name,
    type: data.type,
    icon: data.icon || '',
    sortOrder,
    isPreset: 0,
    createdAt: now,
    updatedAt: now,
    deleted: 0
  };

  const stmt = db.prepare(`
    INSERT INTO categories (id, userId, name, type, icon, sortOrder, isPreset, createdAt, updatedAt, deleted)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  stmt.run([
    category.id,
    category.userId,
    category.name,
    category.type,
    category.icon,
    category.sortOrder,
    category.isPreset,
    category.createdAt,
    category.updatedAt,
    category.deleted
  ]);
  stmt.free();
  saveDb();

  return category;
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
  db.run(sql, values);
  saveDb();

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
  saveDb();

  return true;
}

module.exports = { getAll, create, update, remove };