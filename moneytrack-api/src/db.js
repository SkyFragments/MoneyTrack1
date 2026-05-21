const initSqlJs = require('sql.js');
const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path');

const DB_PATH = path.join(__dirname, '..', 'moneytrack.db');

let db = null;
const revokedTokens = new Set();
let writePromise = Promise.resolve();

function revokeToken(token) {
  try {
    const decoded = jwt.decode(token);
    if (decoded?.exp) {
      const msLeft = decoded.exp * 1000 - Date.now();
      if (msLeft > 0) revokedTokens.add(token);
      // Auto-cleanup after expiry
      setTimeout(() => revokedTokens.delete(token), msLeft);
    }
  } catch {}
}

function isTokenRevoked(token) {
  return revokedTokens.has(token);
}

function getLastInsertId(database) {
  const s = database.prepare('SELECT last_insert_rowid() as id');
  s.step();
  const id = s.getAsObject().id;
  s.free();
  return id;
}

async function getDb() {
  try {
    if (db) return db;

    const SQL = await initSqlJs();
    if (fs.existsSync(DB_PATH)) {
      const buffer = fs.readFileSync(DB_PATH);
      db = new SQL.Database(buffer);
    } else {
      db = new SQL.Database();
    }
    return db;
  } catch (error) {
    throw new Error(`Failed to get database: ${error instanceof Error ? error.message : String(error)}`);
  }
}

function saveDbAsync() {
  return new Promise((resolve) => {
    writePromise = writePromise.then(async () => {
      try {
        if (db) {
          const data = db.export();
          const buffer = Buffer.from(data);
          fs.writeFileSync(DB_PATH, buffer);
        }
      } catch (error) {
        console.error('saveDb failed:', error);
        throw error;
      } finally {
        resolve();
      }
    });
  });
}

function saveDb() {
  return saveDbAsync();
}

async function initializeDatabase() {
  try {
    const database = await getDb();

  // users
  database.run(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      email TEXT UNIQUE NOT NULL,
      password TEXT,
      huaweiOpenId TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      deleted INTEGER DEFAULT 0
    )
  `);

  // accounts
  database.run(`
    CREATE TABLE IF NOT EXISTS accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId TEXT NOT NULL,
      name TEXT DEFAULT '',
      type TEXT DEFAULT 'default',
      date TEXT DEFAULT '01',
      accountIncome REAL DEFAULT 0,
      accountExpense REAL DEFAULT 0,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      deleted INTEGER DEFAULT 0
    )
  `);

  // transactions
  database.run(`
    CREATE TABLE IF NOT EXISTS transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId TEXT NOT NULL,
      accountId INTEGER NOT NULL,
      resource INTEGER NOT NULL,
      type TEXT DEFAULT '',
      amount REAL NOT NULL,
      date TEXT NOT NULL,
      note TEXT DEFAULT '',
      excluded INTEGER DEFAULT 0,
      assetId INTEGER DEFAULT NULL,
      localId INTEGER,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      deleted INTEGER DEFAULT 0
    )
  `);

  // categories
  database.run(`
    CREATE TABLE IF NOT EXISTS categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      key INTEGER,
      userId TEXT,
      name TEXT NOT NULL,
      type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
      icon TEXT,
      sortOrder INTEGER DEFAULT 0,
      isPreset INTEGER DEFAULT 0,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      deleted INTEGER DEFAULT 0
    )
  `);

  // assets
  database.run(`
    CREATE TABLE IF NOT EXISTS assets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId TEXT NOT NULL,
      name TEXT DEFAULT '',
      type INTEGER CHECK(type IN (1, 2, 3)),
      subType INTEGER NOT NULL,
      category INTEGER NOT NULL CHECK(category IN (1, 2)),
      amount REAL NOT NULL DEFAULT 0,
      note TEXT DEFAULT '',
      isCustom INTEGER DEFAULT 0,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      deleted INTEGER DEFAULT 0
    )
  `);

  // budgets
  database.run(`
    CREATE TABLE IF NOT EXISTS budgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId TEXT NOT NULL,
      accountId INTEGER NOT NULL,
      month TEXT NOT NULL,
      amount REAL NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      deleted INTEGER DEFAULT 0,
      UNIQUE(accountId, month)
    )
  `);

  const result = database.exec('SELECT COUNT(*) as count FROM categories WHERE isPreset = 1');
  let count = 0;
  if (result.length > 0 && result[0].values.length > 0 && result[0].values[0].length > 0) {
    count = result[0].values[0][0];
  }

  if (count === 0) {
    const now = new Date().toISOString();
    const presetCategories = [
      // 支出分类 (key 101-119)
      { key: 101, name: '餐饮', type: 'expense', icon: '🍜', sortOrder: 1 },
      { key: 102, name: '交通', type: 'expense', icon: '🚗', sortOrder: 2 },
      { key: 103, name: '服饰', type: 'expense', icon: '👔', sortOrder: 3 },
      { key: 104, name: '购物', type: 'expense', icon: '🛒', sortOrder: 4 },
      { key: 105, name: '服务', type: 'expense', icon: '🔧', sortOrder: 5 },
      { key: 106, name: '教育', type: 'expense', icon: '📚', sortOrder: 6 },
      { key: 107, name: '娱乐', type: 'expense', icon: '🎮', sortOrder: 7 },
      { key: 108, name: '运动', type: 'expense', icon: '⚽', sortOrder: 8 },
      { key: 109, name: '生活缴费', type: 'expense', icon: '💡', sortOrder: 9 },
      { key: 110, name: '旅行', type: 'expense', icon: '✈️', sortOrder: 10 },
      { key: 111, name: '宠物', type: 'expense', icon: '🐶', sortOrder: 11 },
      { key: 112, name: '医疗', type: 'expense', icon: '🏥', sortOrder: 12 },
      { key: 113, name: '保险', type: 'expense', icon: '🛡️', sortOrder: 13 },
      { key: 114, name: '公益', type: 'expense', icon: '❤️', sortOrder: 14 },
      { key: 115, name: '亲子', type: 'expense', icon: '👶', sortOrder: 15 },
      { key: 116, name: '酒店', type: 'expense', icon: '🏨', sortOrder: 16 },
      { key: 117, name: '美容', type: 'expense', icon: '💄', sortOrder: 17 },
      { key: 118, name: '人情', type: 'expense', icon: '🎁', sortOrder: 18 },
      { key: 119, name: '其他', type: 'expense', icon: '📌', sortOrder: 19 },
      // 收入分类 (key 201-204)
      { key: 201, name: '工资', type: 'income', icon: '💰', sortOrder: 1 },
      { key: 202, name: '兼职', type: 'income', icon: '💼', sortOrder: 2 },
      { key: 203, name: '退款', type: 'income', icon: '🔙', sortOrder: 3 },
      { key: 204, name: '其他', type: 'income', icon: '💵', sortOrder: 4 },
    ];

    const stmt = database.prepare(`
      INSERT INTO categories (key, userId, name, type, icon, sortOrder, isPreset, createdAt, updatedAt)
      VALUES (?, NULL, ?, ?, ?, ?, 1, ?, ?)
    `);

    for (const cat of presetCategories) {
      stmt.run([cat.key, cat.name, cat.type, cat.icon, cat.sortOrder, now, now]);
    }
    stmt.free();
    await saveDb();
    }
  } catch (error) {
    throw new Error(`Failed to initialize database: ${error instanceof Error ? error.message : String(error)}`);
  }
  // Database initialized
}

module.exports = { getDb, initializeDatabase, saveDb, saveDbAsync, revokeToken, isTokenRevoked, getLastInsertId };