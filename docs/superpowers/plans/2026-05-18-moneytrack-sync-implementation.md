# MoneyTrack 数据同步后端实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 搭建Node.js/Express后端，实现云端数据持久化，支持MoneyTrack模板的增量同步

**Architecture:** Express + better-sqlite3 + JWT，单设备同步策略（服务端数据优先），软删除标记

**Tech Stack:** Node.js 20, Express 4.x, better-sqlite3, bcrypt, jsonwebtoken

---

## 文件结构

```
moneytrack-api/
├── src/
│   ├── index.js              # 入口，端口3000
│   ├── db.js                 # SQLite初始化
│   ├── middleware/
│   │   └── auth.js           # JWT验证
│   ├── routes/
│   │   ├── auth.js           # 认证路由
│   │   ├── categories.js     # 分类路由
│   │   └── sync.js           # 同步路由
│   └── services/
│       ├── userService.js    # 用户服务
│       ├── syncService.js    # 同步服务
│       └── categoryService.js
├── data/
│   └── moneytrack.db
├── package.json
└── .env
```

---

## Task 1: 项目初始化

**Files:**
- Create: moneytrack-api/package.json
- Create: moneytrack-api/.env
- Create: moneytrack-api/src/index.js
- Create: moneytrack-api/src/db.js

- [ ] Step 1: 创建 package.json
```json
{
  "name": "moneytrack-api",
  "version": "1.0.0",
  "description": "MoneyTrack backend API",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "dev": "node --watch src/index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "better-sqlite3": "^9.4.3",
    "bcrypt": "^5.1.1",
    "jsonwebtoken": "^9.0.2",
    "uuid": "^9.0.1",
    "dotenv": "^16.4.1"
  }
}
```

- [ ] Step 2: 创建 .env
```
PORT=3000
JWT_SECRET=your-super-secret-key-change-in-production
JWT_ACCESS_EXPIRES=2h
JWT_REFRESH_EXPIRES=7d
```

- [ ] Step 3: 创建 db.js（数据库初始化，包含6张表+预置分类）

- [ ] Step 4: 创建 index.js（入口，挂载路由）

- [ ] Step 5: 运行测试：cd moneytrack-api && npm install && node src/index.js

---

## Task 2: JWT认证中间件 + 用户服务

**Files:**
- Create: moneytrack-api/src/middleware/auth.js
- Create: moneytrack-api/src/services/userService.js

- [ ] Step 1: 创建 middleware/auth.js（Bearer token验证）
- [ ] Step 2: 创建 services/userService.js（createUser, validateUser, findById等）

---

## Task 3: 认证路由

**Files:**
- Create: moneytrack-api/src/routes/auth.js

- [ ] 实现：POST /api/auth/register, /login, /refresh, GET /me

---

## Task 4: 分类路由

**Files:**
- Create: moneytrack-api/src/routes/categories.js
- Create: moneytrack-api/src/services/categoryService.js

- [ ] 实现：GET/POST/PUT/DELETE /api/categories，支持预置+自定义分类

---

## Task 5: 同步路由（核心）

**Files:**
- Create: moneytrack-api/src/routes/sync.js
- Create: moneytrack-api/src/services/syncService.js

- [ ] 实现：GET /api/sync/pull?since={timestamp}, POST /api/sync/push

---

## Task 6: 前端对接（HarmonyOS）

**Files:**
- Modify: commons/lib_network/src/main/ets/https/Request.ets（baseURL配置）
- Modify: commons/lib_network/src/main/ets/constants/Enums.ets（新增API路径）
- Create: 同步相关API封装

- [ ] 配置baseURL为实际后端地址（电脑局域网IP）
- [ ] 添加同步相关API路径到RequestUrlMap
- [ ] 创建SyncApis和AuthApis封装

---

## 实施检查清单

| Task | 描述 |
| Task 1 | 项目初始化（package.json, db.js, index.js） |
| Task 2 | JWT中间件 + 用户服务 |
| Task 3 | 认证路由（注册/登录/刷新/me） |
| Task 4 | 分类路由（增删改查） |
| Task 5 | 同步路由（拉取/推送） |
| Task 6 | 前端对接（HTTPS配置） |

**Plan complete.**
