const initSqlJs = require('sql.js');
const fs = require('fs');
const path = require('path');

const DB_PATH = path.join(__dirname, '..', 'moneytrack.db');

let db = null;

async function getDb() {
  if (db) return db;

  const SQL = await initSqlJs();
  if (fs.existsSync(DB_PATH)) {
    const buffer = fs.readFileSync(DB_PATH);
    db = new SQL.Database(buffer);
  } else {
    db = new SQL.Database();
  }
  return db;
}

function saveDb() {
  if (db) {
    const data = db.export();
    const buffer = Buffer.from(data);
    fs.writeFileSync(DB_PATH, buffer);
  }
}

async function initializeDatabase() {
  const database = await getDb();

  // Create users table
  database.run(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      email TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      huaweiOpenId TEXT UNIQUE,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    )
  `);

  // Create categories table
  database.run(`
    CREATE TABLE IF NOT EXISTS categories (
      id TEXT PRIMARY KEY,
      userId TEXT,
      name TEXT NOT NULL,
      type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
      icon TEXT,
      sortOrder INTEGER DEFAULT 0,
      isPreset INTEGER DEFAULT 0,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      deleted INTEGER DEFAULT 0,
      FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  // Create accounts table
  database.run(`
    CREATE TABLE IF NOT EXISTS accounts (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL,
      name TEXT NOT NULL,
      type TEXT DEFAULT 'default',
      date TEXT,
      accountIncome REAL DEFAULT 0,
      accountExpense REAL DEFAULT 0,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      deleted INTEGER DEFAULT 0,
      FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  // Create transactions table
  database.run(`
    CREATE TABLE IF NOT EXISTS transactions (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL,
      accountId TEXT NOT NULL,
      categoryId TEXT,
      type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
      amount REAL NOT NULL,
      date TEXT NOT NULL,
      note TEXT,
      excluded INTEGER DEFAULT 0,
      assetId TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      deleted INTEGER DEFAULT 0,
      FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (accountId) REFERENCES accounts(id) ON DELETE CASCADE,
      FOREIGN KEY (categoryId) REFERENCES categories(id) ON DELETE SET NULL
    )
  `);

  // Create assets table
  database.run(`
    CREATE TABLE IF NOT EXISTS assets (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL,
      name TEXT NOT NULL,
      type INTEGER NOT NULL CHECK(type IN (1, 2, 3)),
      subType TEXT,
      category INTEGER CHECK(category IN (1, 2)),
      amount REAL NOT NULL,
      note TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      deleted INTEGER DEFAULT 0,
      FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  // Create budgets table
  database.run(`
    CREATE TABLE IF NOT EXISTS budgets (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL,
      accountId TEXT,
      month TEXT NOT NULL,
      amount REAL NOT NULL,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      deleted INTEGER DEFAULT 0,
      FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (accountId) REFERENCES accounts(id) ON DELETE SET NULL
    )
  `);

  // Insert preset categories if they don't exist
  const result = database.exec('SELECT COUNT(*) as count FROM categories WHERE isPreset = 1');
  const count = result.length > 0 ? result[0].values[0][0] : 0;

  if (count === 0) {
    const now = new Date().toISOString();
    const presetCategories = [
      { id: 'preset-expense-1', name: '餐饮', type: 'expense', icon: '🍜', sortOrder: 1 },
      { id: 'preset-expense-2', name: '交通', type: 'expense', icon: '🚗', sortOrder: 2 },
      { id: 'preset-expense-3', name: '购物', type: 'expense', icon: '🛒', sortOrder: 3 },
      { id: 'preset-expense-4', name: '娱乐', type: 'expense', icon: '🎮', sortOrder: 4 },
      { id: 'preset-income-1', name: '工资', type: 'income', icon: '💰', sortOrder: 1 },
      { id: 'preset-income-2', name: '其他收入', type: 'income', icon: '💵', sortOrder: 2 },
    ];

    const stmt = database.prepare(`
      INSERT INTO categories (id, userId, name, type, icon, sortOrder, isPreset, createdAt, updatedAt)
      VALUES (?, NULL, ?, ?, ?, ?, 1, ?, ?)
    `);

    for (const cat of presetCategories) {
      stmt.run([cat.id, cat.name, cat.type, cat.icon, cat.sortOrder, now, now]);
    }
    stmt.free();

    saveDb();
  }

  console.log('Database initialized successfully');
}

module.exports = { getDb, initializeDatabase, saveDb };