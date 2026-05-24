# 🎯 MoneyTrack1 项目设计文档

> [!NOTE]
> **项目版本:** `v1.0.0` | **更新日期:** `2026-05-19` | **技术栈:** HarmonyOS + Node.js/Express + sql.js
>
> [!TIP]
> 本文档涵盖系统架构、数据库设计、API接口、同步机制、安全设计等核心内容。

---

## 📑 目录

1. [项目概述](#1-项目概述)
2. [系统架构](#2-系统架构)
3. [前端设计](#3-前端设计)
4. [后端设计](#4-后端设计)
5. [数据库设计](#5-数据库设计)
6. [API接口设计](#6-api接口设计)
7. [同步机制设计](#7-同步机制设计)
8. [安全设计](#8-安全设计)

---

## 1. 项目概述

### 1.1 项目简介

**MoneyTrack1** 是一款面向鸿蒙生态的记账应用，采用 HarmonyOS 原生开发前端，Node.js 构建云端同步服务。支持多设备数据实时同步，用户可通过华为账号一键登录。

### 1.2 核心功能

> [!IMPORTANT]
> 以下为核心功能模块，请确保开发过程中完整实现。

| 功能模块 | 描述 | 优先级 |
|---------|------|--------|
| 🔖 账单管理 | 记录日常收支，支持分类、账户关联 | P0 |
| 💰 资产管理 | 管理现金、银行卡、虚拟资产 | P0 |
| 📊 预算规划 | 按账户月度预算设置与跟踪 | P1 |
| 📈 统计报表 | 可视化收支分析（饼图、折线图） | P1 |
| ☁️ 云端同步 | 跨设备实时数据同步 | P0 |

### 1.3 技术选型

| 层级 | 技术 | 说明 |
|------|------|------|
| 前端 | `HarmonyOS 6.0+` | ArkTS语言，声明式UI框架 |
| 前端UI | `@ohos/mpchart` | 图表可视化 |
| 网络请求 | `@ohos/axios` | HTTP客户端 |
| 本地存储 | `relationalStore` | HarmonyOS SQLite封装 |
| 后端 | `Node.js + Express` | RESTful API服务 |
| 数据库 | `sql.js` | 浏览器端SQLite实现 |
| 认证 | `JWT + 华为授权` | 无密码登录体验 |

> [!TIP]
> **架构决策：** 选择 sql.js 而非传统数据库，是因为 HarmonyOS App 需要本地持久化能力，sql.js 提供与前端 relationalStore 对齐的数据结构。

---

## 2. 系统架构

### 2.1 整体架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                        HarmonyOS App                            │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐            │
│  │  Home   │  │ Assets  │  │Statistics│  │  Mine   │            │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘            │
│       │            │            │            │                  │
│  ┌────┴────────────┴────────────┴────────────┴────┐            │
│  │              bill_data_processing               │            │
│  │         (AccountingDB - relationalStore)        │            │
│  └────────────────────────┬───────────────────────┘            │
│                           │                                      │
│  ┌────────────────────────┴───────────────────────┐            │
│  │                  lib_network                    │            │
│  │              (Request - axios)                 │            │
│  └────────────────────────┬───────────────────────┘            │
└───────────────────────────┼─────────────────────────────────────┘
                            │ HTTPS
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Node.js Backend (Express)                    │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐           │
│  │  Auth   │  │  Sync   │  │  CRUD   │  │Categories│           │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘           │
│       │            │            │            │                  │
│  ┌────┴────────────┴────────────┴────────────┴────┐            │
│  │                    sql.js                       │            │
│  │               (moneytrack.db)                   │            │
│  └─────────────────────────────────────────────────┘            │
└─────────────────────────────────────────────────────────────────┘
```

> [!NOTE]
> **图 2-1：系统架构图** — 展示 HarmonyOS App 与后端服务的交互关系
>
> ![系统架构截图](images/fig-2-1-system-architecture.png)
> *图 2-1：实际系统架构截图（待补充）*

### 2.2 前端模块结构

```
MoneyTrack1/
├── products/
│   └── entry/                    # 设备入口层
├── features/
│   ├── home/                     # 首页模块
│   ├── assets/                   # 资产模块
│   ├── statistics/               # 统计模块
│   └── mine/                     # 我的模块
├── components/                   # 通用组件
│   ├── bill_card/                # 账单卡片
│   ├── bill_chart/               # 账单图表
│   ├── bill_manage/             # 账单管理
│   ├── asset_card/               # 资产卡片
│   └── asset_manage/             # 资产管理
└── commons/
    ├── commonlib/                # 通用工具（router, logger）
    ├── lib_network/              # 网络层（Request封装）
    └── bill_data_processing/     # 数据库层（AccountingDB）
```

### 2.3 后端模块结构

```
moneytrack-api/
├── src/
│   ├── index.js                  # 应用入口
│   ├── db.js                     # 数据库初始化与Schema
│   ├── middleware/
│   │   └── auth.js               # JWT认证中间件
│   ├── routes/
│   │   ├── auth.js               # 认证路由
│   │   ├── accounts.js           # 账户路由
│   │   ├── transactions.js       # 交易路由
│   │   ├── assets.js             # 资产路由
│   │   ├── budgets.js            # 预算路由
│   │   ├── categories.js         # 分类路由
│   │   └── sync.js               # 同步路由
│   └── services/
│       ├── userService.js        # 用户服务
│       ├── categoryService.js    # 分类服务
│       └── syncService.js        # 同步服务
└── moneytrack.db                  # SQLite数据库文件
```

---

## 3. 前端设计

### 3.1 页面结构

| 页面 | 路由 | 功能描述 |
|------|------|----------|
| 首页 | home | 账单列表、月度收支概览 |
| 资产 | assets | 资产卡片展示、资产管理 |
| 统计 | statistics | 图表分析、收支趋势 |
| 我的 | mine | 用户信息、设置 |

> [!NOTE]
> **图 3-1：页面结构截图** — 展示应用首页、资产、统计、我的四大页面
>
> ![页面结构](images/fig-3-1-page-structure.png)
> *图 3-1：页面结构截图（待补充）*

### 3.2 数据层设计

**AccountingDB** 是前端核心数据库类，封装所有数据操作：

```typescript
class AccountingDB {
  transaction(fn: () => void): Promise<void>
  addAccount(account: Account): Promise<number>
  getAccounts(): Promise<Account[]>
  updateAccount(id: number, data: Partial<Account>): Promise<void>
  deleteAccount(id: number): Promise<void>

  addTransaction(transaction: Transaction): Promise<number>
  getTransactions(accountId?: number): Promise<Transaction[]>
  updateTransaction(id: number, data: Partial<Transaction>): Promise<void>
  deleteTransaction(id: number): Promise<void>

  addAsset(asset: Asset): Promise<number>
  getAssets(): Promise<Asset[]>
  updateAsset(id: number, data: Partial<Asset>): Promise<void>
  deleteAsset(id: number): Promise<void>

  addBudget(budget: Budget): Promise<number>
  getBudgets(accountId?: number, month?: string): Promise<Budget[]>
  updateBudget(id: number, data: Partial<Budget>): Promise<void>
  deleteBudget(id: number): Promise<void>
}
```

### 3.3 网络层设计

**Request** 是 axios 封装类，提供统一请求体验：

```typescript
// Tailscale 直连
const baseURL = 'http://100.74.103.98:3000'

// 请求拦截器添加Token
// 响应拦截器统一处理code判断
```

> [!NOTE]
> **图 3-2：网络层请求截图** — 展示 Request 封装与 axios 请求配置
>
> ![网络层截图](images/fig-3-2-network-layer.png)
> *图 3-2：网络层请求截图（待补充）*

---

## 4. 后端设计

### 4.1 认证流程

```
┌────────┐     ┌──────────┐     ┌───────────┐     ┌──────────┐
│ Client │────▶│ /api/auth│────▶│ 华为OAuth │────▶│ JWT Token │
└────────┘     └──────────┘     └───────────┘     └──────────┘
```

**登录流程：**
1. 客户端调用 `POST /api/auth/huawei`
2. 后端通过华为授权获取 OpenId
3. 后端查找/创建用户记录，生成 JWT
4. 返回 token 给客户端

### 4.2 中间件设计

**authMiddleware** 验证流程：
1. 从请求头 `Authorization: Bearer <token>` 提取 token
2. 使用 `jsonwebtoken` 验证 token 有效性
3. 验证通过则将 `userId` 挂载到 `req.userId`
4. 验证失败返回 401

---

## 5. 数据库设计

> [!WARNING]
> 数据库 Schema 必须与前端 `AccountingDB.ets` 保持一致，字段类型和约束不得随意修改。

### 5.1 ER图

```
┌─────────────┐       ┌─────────────────┐       ┌─────────────┐
│   users     │       │    accounts      │       │ transactions│
├─────────────┤       ├─────────────────┤       ├─────────────┤
│ id (PK)     │◀──────│ userId (FK)     │◀──────│ userId (FK) │
│ email       │       │ id (PK)         │       │ accountId(FK)│
│ huaweiOpenId│       │ name            │       │ resource    │
│ createdAt   │       │ type            │       │ type        │
│ updatedAt   │       │ accountIncome   │       │ amount      │
│ deleted     │       │ accountExpense   │       │ date        │
└─────────────┘       │ createdAt       │       │ note        │
                      │ updatedAt       │       │ deleted     │
                      │ deleted         │       └─────────────┘
                      └─────────────────┘
                             ▲
                             │
                      ┌──────┴──────┐
                      │   budgets   │
                      ├─────────────┤
                      │ id (PK)     │
                      │ userId (FK) │
                      │ accountId(FK)│
                      │ month        │
                      │ amount       │
                      │ deleted      │
                      └─────────────┘

┌─────────────┐
│  categories │
├─────────────┤
│ id (PK)     │
│ key         │
│ userId (FK) │──┐
│ name        │  │
│ type        │  │  (支出101-119, 收入201-204)
│ icon        │  │
│ isPreset    │◀─┘
│ deleted     │
└─────────────┘

┌─────────────┐
│   assets    │
├─────────────┤
│ id (PK)     │
│ userId (FK) │
│ name        │
│ type (1,2,3)│
│ subType     │
│ category    │
│ amount      │
│ note        │
│ isCustom    │
│ deleted     │
└─────────────┘
```

> [!NOTE]
> **图 5-1：数据库 ER 图** — 展示各表之间的关联关系
>
> ![ER图截图](images/fig-5-1-er-diagram.png)
> *图 5-1：数据库 ER 图截图（待补充）*

> [!TIP]
> **外键关系说明：** `accounts.userId` → `users.id`，`transactions.accountId` → `accounts.id`，`budgets.accountId` → `accounts.id`

### 5.2 表结构详情

#### users 用户表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | `TEXT` | PRIMARY KEY | 用户唯一标识 (UUID) |
| email | `TEXT` | UNIQUE NOT NULL | 邮箱 |
| password | `TEXT` | - | 密码（可选） |
| huaweiOpenId | `TEXT` | - | 华为授权ID |
| createdAt | `TEXT` | NOT NULL | 创建时间 (ISO8601) |
| updatedAt | `TEXT` | NOT NULL | 更新时间 (ISO8601) |
| deleted | `INTEGER` | DEFAULT 0 | 软删除标记 |

#### accounts 账户表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | 账户ID |
| userId | TEXT | NOT NULL | 用户ID |
| name | TEXT | DEFAULT '' | 账户名称 |
| type | TEXT | DEFAULT 'default' | 账户类型 |
| date | TEXT | DEFAULT '01' | 账单日 |
| accountIncome | REAL | DEFAULT 0 | 账户收入累计 |
| accountExpense | REAL | DEFAULT 0 | 账户支出累计 |
| createdAt | TEXT | NOT NULL | 创建时间 |
| updatedAt | TEXT | NOT NULL | 更新时间 |
| deleted | INTEGER | DEFAULT 0 | 软删除标记 |

#### transactions 交易表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | 交易ID |
| userId | TEXT | NOT NULL | 用户ID |
| accountId | INTEGER | NOT NULL | 关联账户ID |
| resource | INTEGER | NOT NULL | 分类资源ID |
| type | TEXT | DEFAULT '' | 交易类型（income/expense） |
| amount | REAL | NOT NULL | 金额 |
| date | TEXT | NOT NULL | 交易日期 |
| note | TEXT | DEFAULT '' | 备注 |
| excluded | INTEGER | DEFAULT 0 | 是否剔除 |
| assetId | INTEGER | DEFAULT NULL | 关联资产ID |
| localId | INTEGER | - | 客户端本地ID |
| createdAt | TEXT | NOT NULL | 创建时间 |
| updatedAt | TEXT | NOT NULL | 更新时间 |
| deleted | INTEGER | DEFAULT 0 | 软删除标记 |

#### categories 分类表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | 分类ID |
| key | INTEGER | - | 分类键值 |
| userId | TEXT | - | 用户ID（NULL=系统预设） |
| name | TEXT | NOT NULL | 分类名称 |
| type | TEXT | NOT NULL CHECK(type IN ('income','expense')) | 类型 |
| icon | TEXT | - | 图标 |
| sortOrder | INTEGER | DEFAULT 0 | 排序 |
| isPreset | INTEGER | DEFAULT 0 | 是否预设（1=系统预设） |
| createdAt | TEXT | NOT NULL | 创建时间 |
| updatedAt | TEXT | NOT NULL | 更新时间 |
| deleted | INTEGER | DEFAULT 0 | 软删除标记 |

**预设分类：**
- 支出分类（key 101-119）：餐饮、交通、服饰、购物、服务、教育、娱乐、运动、生活缴费、旅行、宠物、医疗、保险、公益、亲子、酒店、美容、人情、其他
- 收入分类（key 201-204）：工资、兼职、退款、其他

#### assets 资产表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | 资产ID |
| userId | TEXT | NOT NULL | 用户ID |
| name | TEXT | DEFAULT '' | 资产名称 |
| type | INTEGER | CHECK(type IN (1,2,3)) | 资产类型 |
| subType | INTEGER | NOT NULL | 子类型 |
| category | INTEGER | NOT NULL CHECK(category IN (1,2)) | 分类 |
| amount | REAL | NOT NULL DEFAULT 0 | 金额 |
| note | TEXT | DEFAULT '' | 备注 |
| isCustom | INTEGER | DEFAULT 0 | 是否自定义 |
| createdAt | TEXT | NOT NULL | 创建时间 |
| updatedAt | TEXT | NOT NULL | 更新时间 |
| deleted | INTEGER | DEFAULT 0 | 软删除标记 |

#### budgets 预算表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | 预算ID |
| userId | TEXT | NOT NULL | 用户ID |
| accountId | INTEGER | NOT NULL | 账户ID |
| month | TEXT | NOT NULL | 月份（YYYY-MM） |
| amount | REAL | NOT NULL DEFAULT 0 | 预算金额 |
| createdAt | TEXT | NOT NULL | 创建时间 |
| updatedAt | TEXT | NOT NULL | 更新时间 |
| deleted | INTEGER | DEFAULT 0 | 软删除标记 |
| - | - | UNIQUE(accountId, month) | 账户月份唯一约束 |

---

## 6. API接口设计

> [!NOTE]
> 所有 API 遵循统一的响应格式 `{ code: number, data: any, msg?: string }`
> - `code: 0` 表示成功
> - `code: 4xx/5xx` 表示错误

### 6.1 认证接口

#### POST /api/auth/huawei
> 华为账号登录接口

**Request:**
```json
{
  "openId": "string",
  "email": "string"
}
```

**Response:**
```json
{
  "code": 0,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "user": {
      "id": "uuid-string",
      "email": "user@example.com"
    }
  }
}
```

### 6.2 数据接口

#### GET /api/accounts
> 获取账户列表

**Response:**
```json
{
  "code": 0,
  "data": [
    {
      "accountId": 1,
      "userId": "user_xxx",
      "name": "我的账户",
      "type": "default",
      "date": "01",
      "accountIncome": 5000.00,
      "accountExpense": 3000.00,
      "createdAt": "2026-01-01T00:00:00Z",
      "updatedAt": "2026-01-01T00:00:00Z"
    }
  ]
}
```

#### POST /api/accounts
> 创建账户

**Request:**
```json
{
  "name": "string",
  "type": "default",
  "date": "01"
}
```

#### GET /api/transactions
> 获取交易列表

**Query Parameters:**
| 参数 | 类型 | 说明 |
|------|------|------|
| accountId | number | 按账户筛选 |
| since | timestamp | 按更新时间筛选 |

#### POST /api/transactions
> 创建交易（自动更新账户收支累计）

#### GET /api/assets
> 获取资产列表

#### POST /api/assets
> 创建资产

#### GET /api/budgets
> 获取预算列表

**Query Parameters:**
| 参数 | 类型 | 说明 |
|------|------|------|
| accountId | number | 按账户筛选 |
| month | string | 按月份筛选 (YYYY-MM) |

#### POST /api/budgets
> 创建/更新预算（按accountId+month upsert）

### 6.3 同步接口

> [!IMPORTANT]
> 同步接口是核心功能，请确保实现完整。

#### GET /api/sync/pull
> 服务端拉取增量数据

**Query Parameters:**
| 参数 | 类型 | 说明 |
|------|------|------|
| since | timestamp | 拉取此时间之后的数据，0 表示全量 |

**Response:**
```json
{
  "code": 0,
  "data": {
    "accounts": [...],
    "transactions": [...],
    "assets": [...],
    "budgets": [...],
    "categories": [...],
    "serverTime": 1704153600000
  }
}
```

#### POST /api/sync/push
> 客户端推送数据

**Request:**
```json
{
  "accounts": [...],
  "transactions": [...],
  "assets": [...],
  "budgets": [...]
}
```

**Response:**
```json
{
  "code": 0,
  "data": {
    "counts": {
      "accounts": 1,
      "transactions": 5,
      "assets": 0,
      "budgets": 1
    },
    "mappings": [
      {"table": "accounts", "localId": 123, "serverId": 456}
    ]
  }
}
```

> [!TIP]
> **localId 与 serverId 映射：** 客户端使用 localId 标识本地记录，服务端生成 serverId 返回后，客户端需要更新本地的 ID 映射关系。

---

## 7. 同步机制设计

### 7.1 同步策略

**拉取（Pull）：**
- 客户端记录 `lastSyncTime`
- 服务端返回 `updatedAt > lastSyncTime` 的所有记录
- 包含预置分类数据下发

**推送（Push）：**
- 客户端批量提交本地新增/修改数据
- 服务端为每条记录生成 `serverId` 替代 `localId`
- 返回 ID 映射表供客户端更新本地映射

### 7.2 冲突处理

- 服务端以 `updatedAt` 为主，丢失本地未同步的修改
- 软删除记录通过 `deleted=1` 标记，不物理删除

### 7.3 字段映射

| 数据库字段 | API返回字段 | 说明 |
|-----------|-------------|------|
| id | accountId/transactionId/assetId/budgetId | 服务端ID |
| resource | resource | 分类键值 |
| localId | localId | 客户端本地ID |

---

## 8. 安全设计

> [!CAUTION]
> 安全是系统的重要保障，请务必按照以下规范实施。

### 8.1 认证安全

| 措施 | 说明 | 状态 |
|------|------|------|
| 🔐 JWT Token | 有效期24小时，防篡改签名 | ✅ 已实现 |
| 🔑 华为OAuth | 无密码登录，避免密码泄露 | ✅ 已实现 |
| 🔒 HTTP only | 生产环境需启用 HTTPS | ⚠️ 待配置 |

### 8.2 数据安全

| 措施 | 说明 | 状态 |
|------|------|------|
| 🛡️ 参数化查询 | 防止 SQL 注入 | ✅ 已实现 |
| ✅ 输入验证 | 所有 API 输入进行类型/范围校验 | ✅ 已实现 |
| 🔄 软删除 | 数据不物理删除，支持恢复 | ✅ 已实现 |

### 8.3 接口防护

| 措施 | 说明 | 状态 |
|------|------|------|
| 🔒 Auth Middleware | 所有数据接口需要有效 Token | ✅ 已实现 |
| 👤 所有权校验 | 查询/修改操作验证 userId 归属 | ✅ 已实现 |
| 🎭 错误掩码 | API 错误不泄漏内部实现细节 | ✅ 已实现 |

---

## 附录

> [!TIP]
> **快速参考：** 以下是常用的配置和环境信息。

### A. 开发环境配置

| 配置项 | 值 | 说明 |
|--------|-----|------|
| 后端端口 | `3000` | Express 服务端口 |
| Tailscale IP | `100.74.103.98` | VPN 连接地址 |
| 数据库文件 | `moneytrack.db` | SQLite 数据库路径 |
| JWT 密钥 | 环境变量 | 生产环境请使用强密钥 |

### B. 技术栈版本

| 技术 | 版本 | 文档 |
|------|------|------|
| HarmonyOS | `6.0.0+` | [官方文档](https://developer.huawei.com) |
| DevEco Studio | `6.0.0+` | [官方文档](https://developer.huawei.com) |
| Node.js | `18+` | [官方文档](https://nodejs.org) |
| Express | `^4.18` | [官方文档](https://expressjs.com) |
| sql.js | `^1.8` | [官方文档](https://sql.js.org) |

---

> [!IMPORTANT]
> **文档最后更新：** 2026-05-19 | 如有问题请联系开发者