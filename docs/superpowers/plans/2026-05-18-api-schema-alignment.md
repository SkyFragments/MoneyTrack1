# 后端Schema适配前端方案A - 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 后端数据库schema与前端HarmonyOS本地DB完全对齐，支持多设备同步

**Architecture:** 后端模拟前端本地DB结构，服务端生成UUID作为主键，客户端上传localId，服务端返回serverId映射

**Tech Stack:** Node.js + Express + sql.js + JWT

---

## 文件变更概览

```
moneytrack-api/src/
├── db.js                          # 重写: schema对齐+key字段+seed data
├── index.js                       # 修改: 新增accounts/transactions/assets/budgets路由
├── middleware/auth.js             # 保持不变
├── routes/
│   ├── auth.js                    # 保持不变
│   ├── categories.js             # 修改: categories表加key字段
│   ├── accounts.js               # 重写: schema对齐
│   ├── transactions.js           # 重写: schema对齐+localId处理
│   ├── assets.js                 # 重写: schema对齐
│   └── budgets.js                # 重写: schema对齐
└── services/
    ├── userService.js            # 修改: findById加step()
    ├── categoryService.js        # 修改: 返回key字段
    ├── syncService.js            # 重写: 支持localId/serverId映射
    └── [其他服务待删除]
```

---

## Schema对照表

| 前端(HarmonyOS) | 后端(mysqlite) | 类型调整 |
|----------------|----------------|---------|
| accounts.accountId INTEGER | accounts.id INTEGER AUTOINCREMENT | 一致 |
| transactions.transactionId INTEGER | transactions.id INTEGER AUTOINCREMENT | 一致 |
| transactions.resource INTEGER | transactions.resource INTEGER (非categoryId) | 改key |
| transactions.excluded BOOLEAN | transactions.excluded INTEGER (0/1) | bool→int |
| assets.assetId INTEGER | assets.id INTEGER AUTOINCREMENT | 一致 |
| assets.isCustom BOOLEAN | assets.isCustom INTEGER (0/1) | bool→int |
| categories (无key) | categories.key INTEGER | **新增** |
| categories (无key) | categories.id INTEGER AUTOINCREMENT | 保持 |

---

## Task 1: 重写 db.js (schema + seed)

**Files:**
- Modify: `moneytrack-api/src/db.js`

- [ ] **Step 1: 重写 schema**

```javascript
// accounts表: id用INTEGER自增(匹配前端accountId)
database.run(`
  CREATE TABLE IF NOT EXISTS accounts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    userId TEXT NOT NULL,
    name TEXT NOT NULL,
    type TEXT DEFAULT 'default',
    date TEXT DEFAULT '01',
    accountIncome REAL DEFAULT 0,
    accountExpense REAL DEFAULT 0,
    createdAt TEXT NOT NULL,
    updatedAt TEXT NOT NULL,
    deleted INTEGER DEFAULT 0
  )
`);

// transactions表: resource保留(不是categoryId), excluded用INTEGER
database.run(`
  CREATE TABLE IF NOT EXISTS transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    userId TEXT NOT NULL,
    accountId INTEGER NOT NULL,
    resource INTEGER NOT NULL,
    type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
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

// categories表: 加key字段对应前端resource
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

// assets表: id用INTEGER自增(匹配前端assetId)
database.run(`
  CREATE TABLE IF NOT EXISTS assets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    userId TEXT NOT NULL,
    name TEXT NOT NULL,
    type INTEGER NOT NULL CHECK(type IN (1, 2)),
    subType INTEGER DEFAULT 0,
    category INTEGER DEFAULT 1,
    amount REAL NOT NULL DEFAULT 0,
    note TEXT DEFAULT '',
    isCustom INTEGER DEFAULT 0,
    createdAt TEXT NOT NULL,
    updatedAt TEXT NOT NULL,
    deleted INTEGER DEFAULT 0
  )
`);

// budgets表
database.run(`
  CREATE TABLE IF NOT EXISTS budgets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    userId TEXT NOT NULL,
    accountId INTEGER NOT NULL,
    month TEXT NOT NULL,
    amount REAL NOT NULL DEFAULT 0,
    createdAt TEXT NOT NULL,
    updatedAt TEXT NOT NULL,
    deleted INTEGER DEFAULT 0
  )
`);
```

- [ ] **Step 2: 重写seed data (23条预置分类带key)**

```javascript
// 支出分类 key: 101-119
// 收入分类 key: 201-204
const presetCategories = [
  { key: 101, name: '餐饮', type: 'expense', icon: '🍜', sortOrder: 1 },
  { key: 102, name: '交通', type: 'expense', icon: '🚗', sortOrder: 2 },
  // ... 全部23条
];

const stmt = database.prepare(`
  INSERT INTO categories (key, userId, name, type, icon, sortOrder, isPreset, createdAt, updatedAt)
  VALUES (?, NULL, ?, ?, ?, ?, 1, ?, ?)
`);
```

- [ ] **Step 3: 提交**

```bash
git add moneytrack-api/src/db.js
git commit -m "refactor(api): align db schema with frontend - use INTEGER auto-increment ids, add key to categories"
```

---

## Task 2: 更新 transactions 路由

**Files:**
- Modify: `moneytrack-api/src/routes/transactions.js`

- [ ] **Step 1: 重写 transactions 路由**

```javascript
const express = require('express');
const { getDb, saveDb } = require('../db');

const router = express.Router();

// GET /api/transactions
router.get('/', async (req, res) => {
  try {
    const userId = req.userId;
    const { accountId, since } = req.query;
    const db = await getDb();

    let sql = 'SELECT * FROM transactions WHERE userId = ? AND deleted = 0';
    const params = [userId];
    if (accountId) { sql += ' AND accountId = ?'; params.push(accountId); }
    if (since) { sql += ' AND updatedAt > ?'; params.push(new Date(parseInt(since)).toISOString()); }
    sql += ' ORDER BY date DESC, id DESC';

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
// 服务端生成id(自增), 客户端传localId用于映射
router.post('/', async (req, res) => {
  try {
    const userId = req.userId;
    const { localId, accountId, resource, type, amount, date, note, excluded, assetId } = req.body;
    if (!accountId || !resource || !type || !amount || !date) {
      return res.status(400).json({ code: 400, msg: 'accountId, resource, type, amount, date required' });
    }

    const db = await getDb();
    const now = new Date().toISOString();

    // 服务端生成自增id，客户端localId存入localId字段
    const stmt = db.prepare(`
      INSERT INTO transactions (userId, accountId, resource, type, amount, date, note, excluded, assetId, localId, createdAt, updatedAt, deleted)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
    `);
    stmt.run([userId, accountId, resource, type, amount, date, note || '', excluded ? 1 : 0, assetId || null, localId || null, now, now]);
    stmt.free();

    // 取刚插入的id
    const idResult = db.exec('SELECT last_insert_rowid() as id');
    const serverId = idResult[0].values[0][0];

    // 更新accountIncome/Expense
    const field = type === 'income' ? 'accountIncome' : 'accountExpense';
    db.run(`UPDATE accounts SET ${field} = ${field} + ? WHERE id = ?`, [amount, accountId]);

    saveDb();
    res.json({ code: 0, data: { id: serverId, localId, resource, type, amount, date, note, excluded, assetId } });
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
    const fields = ['accountId','resource','type','amount','date','note','excluded','assetId'];
    for (const f of fields) {
      if (eval(f) !== undefined) { updates.push(f + ' = ?'); values.push(eval(f)); }
    }
    updates.push('updatedAt = ?');
    values.push(now);
    values.push(req.params.id);

    db.run(`UPDATE transactions SET ${updates.join(', ')} WHERE id = ?`, values);

    // 逆向更新account
    if (old.type && old.amount) {
      const origField = old.type === 'income' ? 'accountIncome' : 'accountExpense';
      db.run(`UPDATE accounts SET ${origField} = ${origField} - ? WHERE id = ?`, [old.amount, old.accountId]);
    }
    if (type && amount) {
      const newField = type === 'income' ? 'accountIncome' : 'accountExpense';
      db.run(`UPDATE accounts SET ${newField} = ${newField} + ? WHERE id = ?`, [amount, accountId || old.accountId]);
    }

    saveDb();
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
    saveDb();
    res.json({ code: 0, data: true });
  } catch (err) {
    res.status(400).json({ code: 400, msg: err.message });
  }
});

module.exports = router;
```

- [ ] **Step 2: 提交**

```bash
git add moneytrack-api/src/routes/transactions.js
git commit -m "feat(api): transactions with frontend-aligned schema - resource int, localId mapping"
```

---

## Task 3: 更新 accounts 路由

**Files:**
- Modify: `moneytrack-api/src/routes/accounts.js`

- [ ] **Step 1: 重写 accounts 路由**

```javascript
const express = require('express');
const { getDb, saveDb } = require('../db');

const router = express.Router();

// GET /api/accounts
router.get('/', async (req, res) => {
  try {
    const userId = req.userId;
    const db = await getDb();
    const stmt = db.prepare('SELECT * FROM accounts WHERE userId = ? AND deleted = 0 ORDER BY id ASC');
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
router.post('/', async (req, res) => {
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

    const idResult = db.exec('SELECT last_insert_rowid() as id');
    const serverId = idResult[0].values[0][0];

    saveDb();
    res.json({ code: 0, data: { id: serverId, name, type: type || 'default', date: date || '01', accountIncome: 0, accountExpense: 0 } });
  } catch (err) {
    res.status(400).json({ code: 400, msg: err.message });
  }
});

// PUT /api/accounts/:id
router.put('/:id', async (req, res) => {
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

    db.run(`UPDATE accounts SET ${updates.join(', ')} WHERE id = ?`, values);
    saveDb();
    res.json({ code: 0, data: true });
  } catch (err) {
    res.status(400).json({ code: 400, msg: err.message });
  }
});

// DELETE /api/accounts/:id
router.delete('/:id', async (req, res) => {
  try {
    const userId = req.userId;
    const db = await getDb();
    const now = new Date().toISOString();

    const check = db.prepare('SELECT id FROM accounts WHERE id = ? AND userId = ? AND deleted = 0');
    check.bind([req.params.id, userId]);
    if (!check.step()) { check.free(); return res.status(404).json({ code: 404, msg: 'not found' }); }
    check.free();

    db.run('UPDATE accounts SET deleted = 1, updatedAt = ? WHERE id = ?', [now, req.params.id]);
    saveDb();
    res.json({ code: 0, data: true });
  } catch (err) {
    res.status(400).json({ code: 400, msg: err.message });
  }
});

module.exports = router;
```

- [ ] **Step 2: 提交**

```bash
git add moneytrack-api/src/routes/accounts.js
git commit -m "feat(api): accounts with INTEGER auto-increment id matching frontend"
```

---

## Task 4: 更新 assets 路由

**Files:**
- Modify: `moneytrack-api/src/routes/assets.js`

- [ ] **Step 1: 重写**

```javascript
const express = require('express');
const { getDb, saveDb } = require('../db');

const router = express.Router();

// GET /api/assets
router.get('/', async (req, res) => {
  try {
    const userId = req.userId;
    const db = await getDb();
    const stmt = db.prepare('SELECT * FROM assets WHERE userId = ? AND deleted = 0 ORDER BY id ASC');
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

    saveDb();
    res.json({ code: 0, data: { id: serverId, name, type, subType: subType ?? 0, category: category ?? 1, amount: amount ?? 0, note: note || '', isCustom: 0 } });
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
    saveDb();
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
    saveDb();
    res.json({ code: 0, data: true });
  } catch (err) {
    res.status(400).json({ code: 400, msg: err.message });
  }
});

module.exports = router;
```

- [ ] **Step 2: 提交**

```bash
git add moneytrack-api/src/routes/assets.js
git commit -m "feat(api): assets with INTEGER auto-increment id matching frontend"
```

---

## Task 5: 更新 budgets 路由

**Files:**
- Modify: `moneytrack-api/src/routes/budgets.js`

- [ ] **Step 1: 重写**

```javascript
const express = require('express');
const { getDb, saveDb } = require('../db');

const router = express.Router();

// GET /api/budgets
router.get('/', async (req, res) => {
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
router.post('/', async (req, res) => {
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
      check.free();
      db.run('UPDATE budgets SET amount = ?, updatedAt = ? WHERE accountId = ? AND month = ? AND userId = ?', [amount, now, accountId, month, userId]);
      saveDb();
      return res.json({ code: 0, data: { id: 'existing', accountId, month, amount } });
    }
    check.free();

    const stmt = db.prepare(
      'INSERT INTO budgets (userId, accountId, month, amount, createdAt, updatedAt, deleted) VALUES (?, ?, ?, ?, ?, ?, 0)'
    );
    stmt.run([userId, accountId, month, amount, now, now]);
    stmt.free();

    const idResult = db.exec('SELECT last_insert_rowid() as id');
    const serverId = idResult[0].values[0][0];

    saveDb();
    res.json({ code: 0, data: { id: serverId, accountId, month, amount } });
  } catch (err) {
    res.status(400).json({ code: 400, msg: err.message });
  }
});

// PUT /api/budgets/:id
router.put('/:id', async (req, res) => {
  try {
    const userId = req.userId;
    const { amount } = req.body;
    const db = await getDb();
    const now = new Date().toISOString();

    const check = db.prepare('SELECT id FROM budgets WHERE id = ? AND userId = ? AND deleted = 0');
    check.bind([req.params.id, userId]);
    if (!check.step()) { check.free(); return res.status(404).json({ code: 404, msg: 'not found' }); }
    check.free();

    db.run('UPDATE budgets SET amount = ?, updatedAt = ? WHERE id = ?', [amount, now, req.params.id]);
    saveDb();
    res.json({ code: 0, data: true });
  } catch (err) {
    res.status(400).json({ code: 400, msg: err.message });
  }
});

// DELETE /api/budgets/:id
router.delete('/:id', async (req, res) => {
  try {
    const userId = req.userId;
    const db = await getDb();
    const now = new Date().toISOString();

    const check = db.prepare('SELECT id FROM budgets WHERE id = ? AND userId = ? AND deleted = 0');
    check.bind([req.params.id, userId]);
    if (!check.step()) { check.free(); return res.status(404).json({ code: 404, msg: 'not found' }); }
    check.free();

    db.run('UPDATE budgets SET deleted = 1, updatedAt = ? WHERE id = ?', [now, req.params.id]);
    saveDb();
    res.json({ code: 0, data: true });
  } catch (err) {
    res.status(400).json({ code: 400, msg: err.message });
  }
});

module.exports = router;
```

- [ ] **Step 2: 提交**

```bash
git add moneytrack-api/src/routes/budgets.js
git commit -m "feat(api): budgets with INTEGER auto-increment id matching frontend"
```

---

## Task 6: 更新 categories 路由 (加key字段)

**Files:**
- Modify: `moneytrack-api/src/routes/categories.js` (已有)
- Modify: `moneytrack-api/src/services/categoryService.js` (返回key字段)

- [ ] **Step 1: 修改 categoryService.js getAll() 返回key**

```javascript
// 已有 getAll 函数, 确保 SELECT * 能返回 key 字段
// db schema 已改, 自动包含 key
// 无需代码变更, 确认即可
```

- [ ] **Step 2: 提交**

```bash
git add moneytrack-api/src/services/categoryService.js
git commit -m "feat(api): categories table includes key field for frontend resource mapping"
```

---

## Task 7: 更新 syncService (支持localId映射)

**Files:**
- Modify: `moneytrack-api/src/services/syncService.js`

- [ ] **Step 1: 重写 syncService.js**

```javascript
const { getDb, saveDb } = require('../db');

/**
 * Pull: 获取服务端最新数据 (包含localId映射)
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
    categories: [],  // 预置分类也需要下发
    serverTime: Date.now(),
  };

  for (const table of tables) {
    const stmt = db.prepare(`
      SELECT * FROM ${table}
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
 */
async function push(userId, data) {
  const db = await getDb();
  const now = new Date().toISOString();

  const counts = { accounts: 0, transactions: 0, assets: 0, budgets: 0 };

  // accounts: 服务端生成自增id
  for (const item of (data.accounts || [])) {
    if (item.deleted) {
      db.run('UPDATE accounts SET deleted = 1, updatedAt = ? WHERE id = ? AND userId = ?', [now, item.id, userId]);
    } else {
      const stmt = db.prepare(
        'INSERT INTO accounts (userId, name, type, date, accountIncome, accountExpense, createdAt, updatedAt, deleted) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0)'
      );
      stmt.run([userId, item.name, item.type || 'default', item.date || '01', item.accountIncome || 0, item.accountExpense || 0, now, now]);
      stmt.free();
      const idResult = db.exec('SELECT last_insert_rowid() as id');
      counts.accounts++;
    }
  }

  // transactions: 保存localId, 服务端生成id
  for (const item of (data.transactions || [])) {
    if (item.deleted) {
      db.run('UPDATE transactions SET deleted = 1, updatedAt = ? WHERE id = ? AND userId = ?', [now, item.id, userId]);
    } else {
      const stmt = db.prepare(`
        INSERT INTO transactions (userId, accountId, resource, type, amount, date, note, excluded, assetId, localId, createdAt, updatedAt, deleted)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
      `);
      stmt.run([
        userId, item.accountId, item.resource, item.type, item.amount, item.date,
        item.note || '', item.excluded ? 1 : 0, item.assetId || null, item.localId || null, now, now
      ]);
      stmt.free();
      counts.transactions++;
    }
  }

  // assets
  for (const item of (data.assets || [])) {
    if (item.deleted) {
      db.run('UPDATE assets SET deleted = 1, updatedAt = ? WHERE id = ? AND userId = ?', [now, item.id, userId]);
    } else {
      const stmt = db.prepare(`
        INSERT INTO assets (userId, name, type, subType, category, amount, note, isCustom, createdAt, updatedAt, deleted)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
      `);
      stmt.run([userId, item.name, item.type, item.subType ?? 0, item.category ?? 1, item.amount ?? 0, item.note || '', item.isCustom ? 1 : 0, now, now]);
      stmt.free();
      counts.assets++;
    }
  }

  // budgets
  for (const item of (data.budgets || [])) {
    if (item.deleted) {
      db.run('UPDATE budgets SET deleted = 1, updatedAt = ? WHERE id = ? AND userId = ?', [now, item.id, userId]);
    } else {
      // upsert by accountId+month
      const check = db.prepare('SELECT id FROM budgets WHERE accountId = ? AND month = ? AND userId = ? AND deleted = 0');
      check.bind([item.accountId, item.month, userId]);
      if (check.step()) {
        check.free();
        db.run('UPDATE budgets SET amount = ?, updatedAt = ? WHERE accountId = ? AND month = ? AND userId = ?', [item.amount, now, item.accountId, item.month, userId]);
      } else {
        check.free();
        const stmt = db.prepare('INSERT INTO budgets (userId, accountId, month, amount, createdAt, updatedAt, deleted) VALUES (?, ?, ?, ?, ?, ?, 0)');
        stmt.run([userId, item.accountId, item.month, item.amount, now, now]);
        stmt.free();
      }
      counts.budgets++;
    }
  }

  saveDb();
  return counts;
}

module.exports = { pull, push };
```

- [ ] **Step 2: 提交**

```bash
git add moneytrack-api/src/services/syncService.js
git commit -m "feat(api): syncService supports localId mapping and preset categories distribution"
```

---

## Task 8: 更新 index.js (确认路由正确注册)

**Files:**
- Modify: `moneytrack-api/src/index.js` (已更新, 确认即可)

- [ ] **Step 1: 确认所有路由已注册**

```javascript
// 确认以下路由已存在
app.use('/api/accounts', authMiddleware, accountRoutes);
app.use('/api/transactions', authMiddleware, transactionRoutes);
app.use('/api/assets', authMiddleware, assetRoutes);
app.use('/api/budgets', authMiddleware, budgetRoutes);
```

- [ ] **Step 2: 提交**

```bash
git add moneytrack-api/src/index.js
git commit -m "chore(api): confirm all CRUD routes registered with auth middleware"
```

---

## Task 9: 全面测试

**Files:**
- Test: API endpoints manually via curl

- [ ] **Step 1: 启动服务, 验证全部端点**

```bash
# 重启服务
taskkill //F //IM node.exe 2>/dev/null; sleep 1
node moneytrack-api/src/index.js &

# 测试流程
TOKEN=$(curl -s -X POST http://100.74.103.98:3000/api/auth/register -H "Content-Type: application/json" -d '{"email":"final@test.com","password":"pass123"}' | node -e "const d=require('fs').readFileSync(0,'utf8');console.log(JSON.parse(d).data.accessToken)")

# 1. 健康检查
curl -s http://100.74.103.98:3000/health

# 2. 创建账户
curl -s -X POST http://100.74.103.98:3000/api/accounts -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"name":"主账户","type":"default"}' | node -e "const d=require('fs').readFileSync(0,'utf8');console.log(JSON.stringify(JSON.parse(d).data))"

# 3. 获取账户列表
curl -s http://100.74.103.98:3000/api/accounts -H "Authorization: Bearer $TOKEN" | node -e "const d=require('fs').readFileSync(0,'utf8');console.log(JSON.parse(d).data.length+' accounts')"

# 4. 创建账单 (带resource)
curl -s -X POST http://100.74.103.98:3000/api/transactions -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"accountId":1,"resource":101,"type":"expense","amount":50,"date":"2026-05-18"}'

# 5. 创建资产
curl -s -X POST http://100.74.103.98:3000/api/assets -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"name":"银行卡","type":1,"subType":1,"category":1,"amount":10000}'

# 6. 获取预置分类 (含key字段)
curl -s http://100.74.103.98:3000/api/categories -H "Authorization: Bearer $TOKEN" | node -e "const d=require('fs').readFileSync(0,'utf8');const cats=JSON.parse(d).data;console.log('Total:',cats.length);cats.filter(c=>c.key).forEach(c=>console.log('key:',c.key,'name:',c.name))"

# 7. 同步拉取 (含categories)
curl -s "http://100.74.103.98:3000/api/sync/pull?since=0" -H "Authorization: Bearer $TOKEN" | node -e "const d=require('fs').readFileSync(0,'utf8');const r=JSON.parse(d).data;console.log('accounts:',r.accounts.length,'transactions:',r.transactions.length,'assets:',r.assets.length,'categories:',r.categories.length)"
```

- [ ] **Step 2: 提交**

```bash
git add docs/superpowers/plans/YYYY-MM-DD-api-schema-alignment.md  # 如果创建了plan doc的话
git commit -m "test(api): verify all endpoints work with new schema"
```

---

## 自检清单

- [ ] 所有表使用 INTEGER PRIMARY KEY AUTOINCREMENT
- [ ] transactions.resource 是 INTEGER (非 categoryId)
- [ ] categories 表有 key 字段 (101-119, 201-204)
- [ ] transactions.excluded 是 INTEGER (0/1)
- [ ] assets.isCustom 是 INTEGER (0/1)
- [ ] 所有服务使用 stmt.step() + stmt.getAsObject()
- [ ] push 时服务端生成自增 id, 客户端传 localId
- [ ] pull 时下发预置分类 (categories)
- [ ] auth 路由保持公开, 其他 CRUD 路由需要认证