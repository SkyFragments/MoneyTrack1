# MoneyTrack 数据同步后端设计

**日期**: 2026-05-18

## 一、目标与范围

**目标**：为MoneyTrack模板搭建Node.js后端，实现云端数据持久化和多设备同步（当前仅手机端）。

**范围**：
- 用户认证（手机号+密码、华为OAuth）
- 账本、交易、资产、预算的增删改查
- 分类数据（预置+用户自定义）
- 增量同步（拉取/推送变更）

**不在范围**：多设备冲突处理、多端实时同步。

## 二、技术架构

| 组件 | 选择 |
|------|------|
| 运行时 | Node.js 20 LTS |
| 框架 | Express 4.x |
| 数据库 | better-sqlite3（同步SQLite） |
| 认证 | JWT（accessToken + refreshToken） |
| 密码加密 | bcrypt |
| 华为OAuth | @huawei/hms-auth（可选，后续实现） |

**项目结构**：
```
moneytrack-api/
├── src/
│   ├── index.js           # 入口，端口3000
│   ├── db.js              # SQLite初始化与连接
│   ├── middleware/
│   │   └── auth.js        # JWT验证中间件
│   ├── routes/
│   │   ├── auth.js        # 认证（注册/登录/华为OAuth）
│   │   ├── categories.js  # 分类管理
│   │   └── sync.js        # 增量同步
│   └── services/
│       ├── userService.js
│       ├── syncService.js
│       └── categoryService.js
├── data/
│   └── moneytrack.db      # SQLite数据库
├── package.json
└── .env
```

## 三、数据库设计

### 3.1 用户表
```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE,
  password TEXT,
  huaweiOpenId TEXT UNIQUE,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL
);
```

### 3.2 分类表（预置+用户自定义）
```sql
CREATE TABLE categories (
  id TEXT PRIMARY KEY,
  userId TEXT,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  icon TEXT,
  sortOrder INTEGER DEFAULT 0,
  isPreset INTEGER DEFAULT 0,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL,
  deleted INTEGER DEFAULT 0
);
```

### 3.3 账本表
```sql
CREATE TABLE accounts (
  id TEXT PRIMARY KEY,
  userId TEXT NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  date TEXT DEFAULT '01',
  accountIncome REAL DEFAULT 0,
  accountExpense REAL DEFAULT 0,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL,
  deleted INTEGER DEFAULT 0
);
```

### 3.4 交易记录表
```sql
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  userId TEXT NOT NULL,
  accountId TEXT NOT NULL,
  categoryId TEXT NOT NULL,
  type TEXT NOT NULL,
  amount REAL NOT NULL,
  date TEXT NOT NULL,
  note TEXT DEFAULT '',
  excluded INTEGER DEFAULT 0,
  assetId TEXT,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL,
  deleted INTEGER DEFAULT 0
);
```

### 3.5 资产表
```sql
CREATE TABLE assets (
  id TEXT PRIMARY KEY,
  userId TEXT NOT NULL,
  name TEXT DEFAULT '',
  type INTEGER NOT NULL,
  subType INTEGER NOT NULL,
  category INTEGER NOT NULL,
  amount REAL NOT NULL DEFAULT 0,
  note TEXT DEFAULT '',
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL,
  deleted INTEGER DEFAULT 0
);
```

### 3.6 预算表
```sql
CREATE TABLE budgets (
  id TEXT PRIMARY KEY,
  userId TEXT NOT NULL,
  accountId TEXT NOT NULL,
  month TEXT NOT NULL,
  amount REAL NOT NULL DEFAULT 0,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL,
  deleted INTEGER DEFAULT 0
);
```

## 四、API设计

### 4.1 认证相关

| 方法 | 路径 | 描述 |
|------|------|------|
| POST | /api/auth/register | 手机号注册 |
| POST | /api/auth/login | 手机号登录 |
| POST | /api/auth/huawei/callback | 华为OAuth回调 |
| POST | /api/auth/refresh | 刷新Token |
| GET | /api/auth/me | 获取当前用户信息 |

### 4.2 数据同步

| 方法 | 路径 | 描述 |
|------|------|------|
| GET | /api/sync/pull?since={timestamp} | 拉取增量变更 |
| POST | /api/sync/push | 推送本地变更 |

### 4.3 分类管理

| 方法 | 路径 | 描述 |
|------|------|------|
| GET | /api/categories | 获取分类列表 |
| POST | /api/categories | 创建自定义分类 |
| PUT | /api/categories/:id | 更新自定义分类 |
| DELETE | /api/categories/:id | 删除自定义分类 |

## 五、前端功能 → 后端API映射

| 前端功能 | 后端API |
|---------|---------|
| 账单查询/筛选 | GET /api/sync/pull → transactions |
| 新增/编辑/删除账单 | POST /api/sync/push → transactions |
| 账本管理 | POST /api/sync/push → accounts |
| 分类管理 | GET/POST/PUT/DELETE /api/categories |
| 资产查询 | GET /api/sync/pull → assets |
| 预算管理 | POST /api/sync/push → budgets |
| 登录/注册 | POST /api/auth/register 或 login |

## 六、关键实现细节

**Token策略**：
- AccessToken：有效期2小时
- RefreshToken：有效期7天
- 每次同步操作自动刷新Token

**冲突处理**：
- 单设备简化：服务端数据优先
- updatedAt字段用于增量判断
- 软删除（deleted标记）

**华为OAuth（后续实现）**：
- Authorization Code → OpenId → 创建/查找用户
