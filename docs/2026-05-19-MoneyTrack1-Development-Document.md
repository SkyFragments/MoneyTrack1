# 🚀 MoneyTrack1 项目开发文档

> [!NOTE]
> **项目版本:** `v1.0.0` | **更新日期:** `2026-05-19` | **技术栈:** HarmonyOS + Node.js/Express + sql.js
>
> [!TIP]
> 本文档为开发者提供完整的技术指南，包含环境搭建、代码示例、测试方法。

---

## 📑 目录

1. [开发环境搭建](#1-开发环境搭建)
2. [项目结构说明](#2-项目结构说明)
3. [前端开发指南](#3-前端开发指南)
4. [后端开发指南](#4-后端开发指南)
5. [数据库操作指南](#5-数据库操作指南)
6. [API调用指南](#6-api调用指南)
7. [同步机制指南](#7-同步机制指南)
8. [测试指南](#8-测试指南)
9. [常见问题处理](#9-常见问题处理)

---

## 1. 开发环境搭建

> [!WARNING]
> 确保所有工具版本符合要求，否则可能导致构建失败。

### 1.1 前端开发环境

**必需工具：**
- ✅ DevEco Studio `6.0.0+`
- ✅ HarmonyOS SDK `6.0.0+`
- ✅ Node.js `18+` (用于后端)

**步骤：**
```bash
# 1. 克隆项目
git clone <repository_url>
cd MoneyTrack1

# 2. 使用 DevEco Studio 打开项目
# 3. 配置签名 (Product > Signing Configs)
# 4. Run > Run 'entry'
```

### 1.2 后端开发环境

```bash
# 1. 进入后端目录
cd moneytrack-api

# 2. 安装依赖
npm install

# 3. 配置环境变量
cp .env.example .env
# 编辑 .env 设置 PORT=3000

# 4. 启动开发服务器
npm run dev
# 服务器运行于 http://localhost:3000
```

### 1.3 Tailscale VPN 连接

> [!IMPORTANT]
> 手机和电脑需在同一 Tailscale 网络才能正常通信。

```bash
# 宿主机 Tailscale IP
100.74.103.98

# 前端请求地址配置 (lib_network/https/Request.ets)
const baseURL = 'http://100.74.103.98:3000'
```

> [!NOTE]
> 若使用真机调试，确保手机已安装并登录 Tailscale。

> [!NOTE]
> **图 1-1：Tailscale VPN 连接示意** — 手机与电脑在同一网络下的配置
>
> ![Tailscale连接截图](images/fig-1-1-tailscale-connection.png)
> *图 1-1：Tailscale VPN 连接配置截图（待补充）*

---

## 2. 项目结构说明

### 2.1 前端目录结构

```
MoneyTrack1/
├── products/
│   └── entry/
│       └── src/main/ets/
│           └── MainEntry.ets          # 应用入口
├── features/
│   ├── home/                          # 首页功能
│   │   └── src/main/ets/
│   │       └── views/HomeIndex.ets    # 首页视图
│   ├── assets/                        # 资产管理
│   ├── statistics/                    # 统计报表
│   └── mine/                          # 用户中心
├── components/
│   ├── bill_card/                     # 账单卡片组件
│   ├── bill_chart/                    # 账单图表组件
│   ├── bill_manage/                   # 账单管理组件
│   ├── asset_card/                    # 资产卡片组件
│   └── asset_manage/                  # 资产管理组件
└── commons/
    ├── commonlib/                     # 通用工具库
    │   └── src/main/ets/
    │       ├── components/            # 通用UI组件
    │       ├── utils/                 # 工具函数 (router, logger)
    │       └── constants/             # 常量定义
    ├── lib_network/                   # 网络请求层
    │   └── src/main/ets/
    │       ├── https/Request.ets     # axios 封装
    │       ├── httpsmock/            # Mock 数据
    │       └── types/                 # 请求/响应类型定义
    └── bill_data_processing/          # 数据处理层
        └── src/main/ets/
            └── utils/accountingdb/
                └── AccountingDB.ets   # 数据库封装
```

> [!NOTE]
> **图 2-1：前端项目目录结构** — 展示各模块和组件的组织方式
>
> ![前端目录结构截图](images/fig-2-1-frontend-structure.png)
> *图 2-1：前端项目目录结构截图（待补充）*

### 2.2 后端目录结构

```
moneytrack-api/
├── src/
│   ├── index.js                      # 应用入口
│   ├── db.js                         # 数据库初始化
│   ├── constants/                    # 常量定义
│   ├── middleware/
│   │   └── auth.js                   # JWT 认证中间件
│   ├── routes/                       # 路由处理
│   │   ├── auth.js                   # 认证路由
│   │   ├── accounts.js              # 账户路由
│   │   ├── transactions.js          # 交易路由
│   │   ├── assets.js                # 资产路由
│   │   ├── budgets.js               # 预算路由
│   │   ├── categories.js           # 分类路由
│   │   └── sync.js                  # 同步路由
│   └── services/                     # 业务逻辑层
│       ├── userService.js           # 用户服务
│       ├── categoryService.js       # 分类服务
│       └── syncService.js           # 同步服务
├── package.json
└── moneytrack.db                     # SQLite 数据库文件
```

### 2.3 关键文件说明

| 文件 | 职责 | 关键API |
|------|------|---------|
| `Request.ets` | HTTP 请求封装 | `GET/POST/PUT/DELETE` |
| `AccountingDB.ets` | 数据库操作封装 | `add/get/update/delete` |
| `db.js` | 数据库 Schema 定义 | `initializeDatabase()` |
| `auth.js` | JWT 认证中间件 | `verifyToken()` |
| `syncService.js` | 数据同步逻辑 | `pull()/push()` |

---

## 3. 前端开发指南

### 3.1 网络请求使用

```typescript
import Request from '../https/Request'

// GET 请求
const accounts = await Request.get('/api/accounts')

// POST 请求
const result = await Request.post('/api/transactions', {
  accountId: 1,
  resource: 101,
  type: 'expense',
  amount: 100,
  date: '2026-05-19'
})

// 带认证的请求 (自动从 storage 获取 token)
Request.defaults.headers['Authorization'] = `Bearer ${token}`
```

> [!NOTE]
> **图 3-1：网络请求示例** — 展示 HTTP 请求的调用方式
>
> ![网络请求示例截图](images/fig-3-1-network-request.png)
> *图 3-1：网络请求示例截图（待补充）*

### 3.2 数据库操作

```typescript
import accountingDB from '../../utils/accountingdb/AccountingDB'

// 添加账户
const accountId = await accountingDB.addAccount({
  name: '我的账户',
  type: 'default',
  date: '01'
})

// 获取账户列表
const accounts = await accountingDB.getAccounts()

// 添加交易
const transactionId = await accountingDB.addTransaction({
  accountId: 1,
  resource: 101,
  type: 'expense',
  amount: 100,
  date: '2026-05-19',
  note: '午餐'
})

// 事务操作
await accountingDB.transaction(async () => {
  await accountingDB.addTransaction({...})
  await accountingDB.updateAccount(1, { accountExpense: 100 })
})
```

### 3.3 路由跳转

```typescript
import RouterModule from 'commonlib'

// 页面跳转
RouterModule.pushUrl('router://assets/AssetManage', {
  assetId: '123'
})

// 打开对话框
RouterModule.openDialog('CommonDialog', {
  title: '确认删除',
  message: '是否确认删除？'
})
```

### 3.4 组件开发规范

```typescript
// 组件文件结构
@Component
export struct MyComponent {
  // 状态装饰器
  @State private data: string = ''
  @Prop @Require title: string  // 外部传入，必填

  build() {
    Column() {
      Text(this.title)
      // ...
    }
  }
}
```

---

## 4. 后端开发指南

> [!IMPORTANT]
> 后端采用 `sql.js` 进行数据库操作，注意 `prepare()` → `bind()` → `step()` → `getAsObject()` → `free()` 的使用模式。

### 4.1 添加新路由

> [!TIP]
> **路由注册规范：** 所有数据接口必须经过 `authMiddleware` 中间件，公共接口（如登录）除外。

**步骤 1: 创建路由文件** `src/routes/example.js`

```javascript
const express = require('express');
const { getDb, saveDb } = require('../db');

const router = express.Router();

// GET /api/example
router.get('/', async (req, res) => {
  try {
    const userId = req.userId;  // 从中间件获取
    const db = await getDb();

    const stmt = db.prepare('SELECT * FROM example WHERE userId = ? AND deleted = 0');
    stmt.bind([userId]);
    const rows = [];
    while (stmt.step()) rows.push(stmt.getAsObject());
    stmt.free();

    res.json({ code: 0, data: rows });
  } catch (err) {
    res.status(500).json({ code: 500, msg: err.message });
  }
});

// POST /api/example
router.post('/', async (req, res) => {
  try {
    const userId = req.userId;
    const { name, value } = req.body;

    if (!name) return res.status(400).json({ code: 400, msg: 'name required' });

    const db = await getDb();
    const now = new Date().toISOString();

    const stmt = db.prepare(
      'INSERT INTO example (userId, name, value, createdAt, updatedAt, deleted) VALUES (?, ?, ?, ?, ?, 0)'
    );
    stmt.run([userId, name, value || '', now, now]);
    stmt.free();

    const idResult = db.exec('SELECT last_insert_rowid() as id');
    const serverId = idResult[0].values[0][0];

    saveDb();
    res.json({ code: 0, data: { id: serverId, name, value } });
  } catch (err) {
    res.status(400).json({ code: 400, msg: err.message });
  }
});

module.exports = router;
```

**步骤 2: 注册路由** `src/index.js`

```javascript
const exampleRoutes = require('./routes/example');

// 添加路由 (注意：数据接口需要 authMiddleware)
app.use('/api/example', authMiddleware, exampleRoutes);
```

### 4.2 数据库 Schema 修改

> [!WARNING]
> 修改数据库 Schema 后，需要重启服务并确保数据库文件已备份。

编辑 `src/db.js` 的 `initializeDatabase()` 函数：

```javascript
async function initializeDatabase() {
  const database = await getDb();

  // 添加新表
  database.run(`
    CREATE TABLE IF NOT EXISTS new_table (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId TEXT NOT NULL,
      name TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      deleted INTEGER DEFAULT 0
    )
  `);

  saveDb();
}
```

### 4.3 中间件编写

> [!NOTE]
> **认证中间件职责：** 验证 Token、提取 userId、挂载到 req 对象。

认证中间件示例 `src/middleware/auth.js`:

```javascript
const jwt = require('jsonwebtoken');
const SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

function authMiddleware(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];

  if (!token) {
    return res.status(401).json({ code: 401, msg: 'No token provided' });
  }

  try {
    const decoded = jwt.verify(token, SECRET);
    req.userId = decoded.userId;
    next();
  } catch (err) {
    return res.status(401).json({ code: 401, msg: 'Invalid token' });
  }
}

module.exports = authMiddleware;
```

---

## 5. 数据库操作指南

### 5.1 sql.js 基础操作

```javascript
const { getDb, saveDb } = require('./db');

// 查询
const db = await getDb();
const stmt = db.prepare('SELECT * FROM users WHERE id = ?');
stmt.bind(['user_123']);
if (stmt.step()) {
  const user = stmt.getAsObject();
}
stmt.free();

// 插入
const insertStmt = db.prepare(
  'INSERT INTO accounts (userId, name, type, createdAt, updatedAt, deleted) VALUES (?, ?, ?, ?, ?, 0)'
);
insertStmt.run(['user_123', '账户名', 'default', now, now]);
insertStmt.free();

// 更新
db.run('UPDATE accounts SET name = ?, updatedAt = ? WHERE id = ?', ['新名称', now, 1]);

// 删除 (软删除)
db.run('UPDATE accounts SET deleted = 1, updatedAt = ? WHERE id = ?', [now, 1]);

// 保存到文件
saveDb();
```

### 5.2 预置分类初始化

数据库初始化时自动创建 23 个预置分类：

```javascript
// 支出分类 (key 101-119)
const expenseCategories = [
  { key: 101, name: '餐饮', icon: '🍜' },
  { key: 102, name: '交通', icon: '🚗' },
  // ... 共 19 个
];

// 收入分类 (key 201-204)
const incomeCategories = [
  { key: 201, name: '工资', icon: '💰' },
  { key: 202, name: '兼职', icon: '💼' },
  { key: 203, name: '退款', icon: '🔙' },
  { key: 204, name: '其他', icon: '💵' },
];
```

### 5.3 数据库备份与恢复

```bash
# 备份
cp moneytrack.db moneytrack_backup_$(date +%Y%m%d).db

# 恢复
cp moneytrack_backup_20260519.db moneytrack.db
```

---

## 6. API调用指南

### 6.1 认证流程

```typescript
// 1. 华为授权登录
const huaweiAuth = await onButtonClick()

// 2. 发送 openId 到后端
const response = await Request.post('/api/auth/huawei', {
  openId: huaweiAuth.openId,
  email: huaweiAuth.email
})

// 3. 保存 token
AppStorage.SetOrCreate('token', response.data.token)

// 4. 后续请求自动携带 token
Request.defaults.headers['Authorization'] = `Bearer ${token}`
```

### 6.2 账户操作

```typescript
// 获取账户列表
const accountsRes = await Request.get('/api/accounts')

// 创建账户
const newAccount = await Request.post('/api/accounts', {
  name: '银行卡',
  type: 'bank',
  date: '15'
})

// 更新账户
await Request.put('/api/accounts/1', {
  name: '新银行卡'
})

// 删除账户 (软删除)
await Request.delete('/api/accounts/1')
```

### 6.3 交易操作

```typescript
// 创建交易 (自动更新账户收支)
const transaction = await Request.post('/api/transactions', {
  accountId: 1,
  resource: 101,  // 餐饮分类
  type: 'expense',
  amount: 50.00,
  date: '2026-05-19',
  note: '午餐'
})

// 更新交易 (自动反向更新账户收支)
await Request.put('/api/transactions/1', {
  amount: 60.00
})

// 删除交易 (自动反向更新账户收支)
await Request.delete('/api/transactions/1')
```

### 6.4 预算操作

```typescript
// 按账户和月份获取预算
const budgets = await Request.get('/api/budgets?accountId=1&month=2026-05')

// 创建或更新预算 (upsert)
await Request.post('/api/budgets', {
  accountId: 1,
  month: '2026-05',
  amount: 5000.00
})
```

---

## 7. 同步机制指南

### 7.1 拉取同步 (Pull)

```typescript
// 1. 获取上次同步时间
const lastSyncTime = AppStorage.Get('lastSyncTime') || 0

// 2. 调用 pull 接口
const syncData = await Request.get(`/api/sync/pull?since=${lastSyncTime}`)

// 3. 更新本地数据库
for (const account of syncData.accounts) {
  await accountingDB.updateAccount(account.accountId, account)
}
// ... 其他表

// 4. 保存同步时间
AppStorage.SetOrCreate('lastSyncTime', syncData.serverTime)
```

### 7.2 推送同步 (Push)

```typescript
// 1. 收集本地未同步数据
const localChanges = {
  accounts: await getLocalUnsyncedAccounts(),
  transactions: await getLocalUnsyncedTransactions(),
  assets: await getLocalUnsyncedAssets(),
  budgets: await getLocalUnsyncedBudgets()
}

// 2. 发送 push 请求
const pushResult = await Request.post('/api/sync/push', localChanges)

// 3. 更新本地 ID 映射
for (const mapping of pushResult.data.mappings) {
  await updateLocalIdMapping(mapping.table, mapping.localId, mapping.serverId)
}
```

> [!NOTE]
> **图 7-1：同步流程示意** — 展示 Push 和 Pull 同步的数据流向
>
> ![同步流程截图](images/fig-7-1-sync-flow.png)
> *图 7-1：同步流程示意图（待补充）*

### 7.3 同步冲突处理

| 场景 | 处理方式 |
|------|----------|
| 本地新增，服务端也有新增 | 以服务端为准，保留本地 localId 映射 |
| 本地修改，服务端也有修改 | 以服务端 `updatedAt` 为准 |
| 本地删除，服务端也有删除 | 统一标记 `deleted=1` |

---

## 8. 测试指南

### 8.1 后端接口测试

```bash
# 健康检查
curl http://localhost:3000/health

# 测试认证 (需提供有效 openId)
curl -X POST http://localhost:3000/api/auth/huawei \
  -H "Content-Type: application/json" \
  -d '{"openId": "test_open_id", "email": "test@example.com"}'

# 测试获取账户 (需携带 token)
curl http://localhost:3000/api/accounts \
  -H "Authorization: Bearer <your_token>"
```

### 8.2 同步流程测试

```bash
# 1. 拉取空数据 (since=0)
curl "http://localhost:3000/api/sync/pull?since=0" \
  -H "Authorization: Bearer <token>"

# 2. 推送测试数据
curl -X POST "http://localhost:3000/api/sync/push" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"accounts": [{"name": "测试账户", "type": "default", "date": "01"}]}'

# 3. 再次拉取验证
curl "http://localhost:3000/api/sync/pull?since=0" \
  -H "Authorization: Bearer <token>"
```

### 8.3 数据库验证

```javascript
// 在 Node REPL 中验证
const { getDb } = require('./db');
const db = await getDb();

// 查看所有表
const tables = db.exec("SELECT name FROM sqlite_master WHERE type='table'");
console.log(tables[0].values);

// 查看用户
const users = db.exec('SELECT * FROM users');
console.log(users[0].values);

// 查看预置分类
const categories = db.exec("SELECT * FROM categories WHERE isPreset = 1");
console.log(categories[0].values);
```

---

## 9. 常见问题处理

> [!IMPORTANT]
> 遇到问题先检查本节，常见问题均有解决方案。

### 9.1 前端问题

**Q: 请求显示网络错误**
- ❌ 检查 Tailscale VPN 是否连接
- ❌ 检查后端服务是否启动 `curl http://localhost:3000/health`
- ❌ 检查 baseURL 配置是否正确

**Q: 数据不同步**
- ❌ 检查 Token 是否过期
- ❌ 检查 lastSyncTime 是否正确保存
- ❌ 检查本地数据库操作是否正确

### 9.2 后端问题

**Q: 服务启动失败**
```bash
# 检查端口占用
netstat -an | grep 3000

# 查看错误日志
node src/index.js
```

**Q: 数据库写入失败**
```bash
# 检查数据库文件权限
ls -la moneytrack.db

# 验证数据库完整性
node -e "const { getDb } = require('./src/db'); getDb().then(db => { console.log(db.exec('PRAGMA integrity_check')) })"
```

### 9.3 同步问题

**Q: Push 返回 counts 全为 0**
- ❌ 检查数据是否包含 `deleted` 标记
- ❌ 检查必填字段是否完整

**Q: Pull 返回空数据**
- ❌ 检查 `since` 参数是否正确
- ❌ 检查服务端数据是否存在

---

## 附录

### A. 环境变量配置

```bash
# moneytrack-api/.env
PORT=3000
JWT_SECRET=your-secret-key-change-in-production
```

### B. Git 工作流程

> [!TIP]
> **分支策略：** 请始终在功能分支上开发，合并前进行代码审查。

```bash
# 创建功能分支
git checkout -b feature/new-feature

# 提交更改 (遵循 conventional commits)
git add .
git commit -m "feat: add new feature"

# 推送到远程
git push -u origin feature/new-feature

# 合并到 main
git checkout main
git merge feature/new-feature
```

### C. 版本信息

| 组件 | 版本 | 备注 |
|------|------|------|
| HarmonyOS | `6.0.0+` | 最低支持版本 |
| DevEco Studio | `6.0.0+` | 开发工具 |
| Node.js | `18+` | 后端运行环境 |
| Express | `^4.18` | Web 框架 |
| sql.js | `^1.8` | SQLite 实现 |

---

> [!IMPORTANT]
> **文档最后更新：** 2026-05-19 | 如有问题请提交 Issue