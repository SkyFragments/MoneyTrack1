# Username Registration + Guest Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add username+password registration and enable guest mode with local-only storage and upgrade path to full account.

**Architecture:** Backend adds username-based auth alongside existing email/huawei. Frontend adds: (1) registration screen, (2) guest mode flag, (3) local-only sync logic, (4) account upgrade flow.

**Tech Stack:** ArkTS/TypeScript (frontend), Node.js/Express (backend), sql.js (DB)

---

## File Map

### Backend (moneytrack-api)
- `src/db.js` — users table schema
- `src/services/userService.js` — user create/validate/lookup
- `src/routes/auth.js` — /register, /login endpoints
- `__tests__/auth.test.js` — auth tests

### Frontend (HarmonyOS)
- `commons/lib_network/src/main/ets/https/apis/Auth.ets` — AuthApis.register
- `commons/lib_network/src/main/ets/constants/Enums.ets` — AUTH_REGISTER URL
- `features/mine/src/main/ets/views/LoginPage.ets` — register entry
- `features/mine/src/main/ets/viewmodels/LoginVM.ets` — LoginUtil.handleRegister, guest detection
- `components/aggregated_login/src/main/ets/components/OtherLoginPage.ets` — registration form
- `components/aggregated_login/src/main/ets/model/Index.ets` — RegisterParams type
- `features/mine/src/main/ets/views/MineView.ets` — guest → full account upgrade
- `commons/lib_network/src/main/ets/utils/authCache.ets` — AuthCache.getUserType/setUserType

---

## Backend Tasks

### Task 1: Backend — Username Registration

**Files:**
- Modify: `moneytrack-api/src/db.js:81-90`
- Modify: `moneytrack-api/src/services/userService.js:7-20,23-41`
- Modify: `moneytrack-api/src/routes/auth.js:31-58,60-72`
- Modify: `moneytrack-api/__tests__/auth.test.js`

- [ ] **Step 1: Add username column to users table**

Modify `db.js` to add `username TEXT UNIQUE NOT NULL` column to users table. Keep email optional (nullable).

```javascript
// db.js — users table
database.run(`
  CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    email TEXT,
    password TEXT,
    huaweiOpenId TEXT,
    userType TEXT DEFAULT 'full',  -- 'full' or 'guest'
    createdAt TEXT NOT NULL,
    updatedAt TEXT NOT NULL,
    deleted INTEGER DEFAULT 0
  )
`);
```

- [ ] **Step 2: Update userService.createUser to accept username**

```javascript
// userService.js
async function createUser(username, password, email = null) {
  const db = await getDb();
  const id = uuidv4();
  const now = new Date().toISOString();
  const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);

  const stmt = db.prepare(
    'INSERT INTO users (id, username, email, password, userType, createdAt, updatedAt) VALUES (?, ?, ?, ?, ?, ?, ?)'
  );
  stmt.run([id, username, email, hashedPassword, 'full', now, now]);
  stmt.free();
  await saveDbAsync();

  return { id, username, email, createdAt: now };
}
```

- [ ] **Step 3: Update userService.validateUser to accept username or email**

```javascript
// userService.js
async function validateUser(usernameOrEmail, password) {
  const db = await getDb();
  const stmt = db.prepare(
    'SELECT id, username, email, password, createdAt FROM users WHERE (username = ? OR email = ?) AND deleted = 0'
  );
  stmt.bind([usernameOrEmail, usernameOrEmail]);
  stmt.step();
  const user = stmt.getAsObject();
  stmt.free();

  if (!user || !user.password) return null;

  const isValid = await bcrypt.compare(password, user.password);
  if (!isValid) return null;

  return { id: user.id, username: user.username, email: user.email, createdAt: user.createdAt };
}
```

- [ ] **Step 4: Update auth.js /register to use username instead of email**

```javascript
// auth.js — POST /register
router.post('/register', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ code: 400, msg: 'Username and password are required' });
    }

    if (typeof username !== 'string' || username.length < 3 || username.length > 30) {
      return res.status(400).json({ code: 400, msg: 'Username must be 3-30 characters' });
    }

    if (typeof password !== 'string' || password.length < 6) {
      return res.status(400).json({ code: 400, msg: 'Password must be at least 6 characters' });
    }

    const user = await userService.createUser(username, password);
    const { accessToken, refreshToken } = generateTokens(user.id);

    res.json({ code: 0, data: { user, accessToken, refreshToken } });
  } catch (err) {
    if (err.message.includes('UNIQUE')) {
      return res.status(400).json({ code: 400, msg: 'Username already exists' });
    }
    res.status(400).json({ code: 400, msg: err.message });
  }
});
```

- [ ] **Step 5: Update auth.js /login to accept username or email**

```javascript
// auth.js — POST /login
router.post('/login', async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ code: 400, msg: 'Username and password are required' });
  }

  const user = await userService.validateUser(username, password);
  if (!user) {
    return res.status(401).json({ code: 401, msg: 'Invalid credentials' });
  }

  const { accessToken, refreshToken } = generateTokens(user.id);
  res.json({ code: 0, data: { user, accessToken, refreshToken } });
});
```

- [ ] **Step 6: Update AuthApis.register on frontend**

Modify `Auth.ets` to change `RegisterParams` from `{email, password}` to `{username, password}`.

```typescript
// Auth.ets
interface RegisterParams {
  username: string;
  password: string;
}
```

- [ ] **Step 7: Run tests and fix failures**

Run: `npm test -- moneytrack-api/__tests__/auth.test.js`

---

### Task 2: Backend — Guest Mode Support

**Files:**
- Modify: `moneytrack-api/src/services/userService.js:65-78`
- Modify: `moneytrack-api/src/db.js` — add guest userType
- Create: `moneytrack-api/src/routes/guest.js` (new file)

- [ ] **Step 1: Add createGuestUser to userService**

```javascript
// userService.js — add new function
async function createGuestUser() {
  const db = await getDb();
  const id = uuidv4();
  const now = new Date().toISOString();
  const username = 'guest_' + id.slice(0, 8);

  const stmt = db.prepare(
    'INSERT INTO users (id, username, userType, createdAt, updatedAt) VALUES (?, ?, ?, ?, ?)'
  );
  stmt.run([id, username, 'guest', now, now]);
  stmt.free();
  await saveDbAsync();

  return { id, username, userType: 'guest', createdAt: now };
}
```

- [ ] **Step 2: Create guest.js route for guest-only operations**

Create `moneytrack-api/src/routes/guest.js`:

```javascript
const express = require('express');
const router = express.Router();
const userService = require('../services/userService');
const authMiddleware = require('../middleware/auth');

// POST /api/guest/create — create guest account
router.post('/create', async (req, res) => {
  try {
    const guest = await userService.createGuestUser();
    const { accessToken, refreshToken } = generateTokens(guest.id);
    res.json({ code: 0, data: { user: guest, accessToken, refreshToken } });
  } catch (err) {
    res.status(500).json({ code: 500, msg: err.message });
  }
});

module.exports = router;
```

- [ ] **Step 3: Create auth middleware for guest-aware routes**

Modify `authMiddleware.js` to check `req.userType` for guest users on sync routes:

```javascript
// middleware/auth.js
function authMiddleware(req, res, next) {
  // existing token validation...
  // After token validation, check userType
  req.userType = user.userType; // 'full' or 'guest'
  next();
}

module.exports = authMiddleware;
```

- [ ] **Step 4: Protect sync routes — guest users can only sync their own data**

Modify `syncService.js` to enforce userId matching for guest users.

- [ ] **Step 5: Commit backend changes**

```bash
git add moneytrack-api/src/
git commit -m "feat: add username registration and guest mode support"
```

---

## Frontend Tasks

### Task 3: Frontend — AuthCache UserType

**Files:**
- Modify: `commons/lib_network/src/main/ets/utils/authCache.ets`

- [ ] **Step 1: Add userType to AuthCache**

```typescript
// authCache.ets
static getUserType(): 'full' | 'guest' | null {
  return preferences.getSync('userType', null) as 'full' | 'guest' | null
}

static setUserType(type: 'full' | 'guest'): void {
  preferences.putSync('userType', type)
}
```

- [ ] **Step 2: Commit**

```bash
git add commons/lib_network/src/main/ets/utils/authCache.ets
git commit -m "feat: add userType to AuthCache"
```

---

### Task 4: Frontend — Registration Screen

**Files:**
- Modify: `components/aggregated_login/src/main/ets/model/Index.ets`
- Modify: `components/aggregated_login/src/main/ets/components/OtherLoginPage.ets`
- Modify: `features/mine/src/main/ets/viewmodels/LoginVM.ets`

- [ ] **Step 1: Add RegisterParams to model/Index.ets**

```typescript
// model/Index.ets — add interface
interface RegisterParams {
  username: string;
  password: string;
}
```

- [ ] **Step 2: Add registration tab to OtherLoginPage**

In `OtherLoginPage.ets`, add a tab/switch for "注册" (register) vs "登录" (login) alongside phone login.

```typescript
@State registerMode: boolean = false
@State registerUsername: string = ''
@State registerPassword: string = ''

// Add UI:
// if (registerMode) {
//   TextInput({ placeholder: '用户名' })...
//   TextInput({ placeholder: '密码' })...
//   Button('注册')...
//   Text('已有账号？登录')...
// } else {
//   existing phone login UI...
// }
```

- [ ] **Step 3: Add LoginUtil.handleRegister**

```typescript
// LoginVM.ets
static async handleRegister(params: RegisterParams): Promise<void> {
  const res = await AuthApis.register(params)
  if (res.code === 0 && res.data) {
    AuthCache.setTokens(res.data.accessToken, res.data.refreshToken)
    AuthCache.setUserId(res.data.user.id)
    AuthCache.setUserType('full')
    iData.global.isLogin = true
    ToastDialog.showToast({ message: '注册成功' })
    RouterModule.pop()
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add components/aggregated_login/src/main/ets/
git add features/mine/src/main/ets/viewmodels/LoginVM.ets
git commit -m "feat: add username registration screen"
```

---

### Task 5: Frontend — Guest Mode Detection + Local-Only

**Files:**
- Modify: `features/mine/src/main/ets/viewmodels/LoginVM.ets`
- Modify: `commons/lib_network/src/main/ets/https/apis/Sync.ets`

- [ ] **Step 1: Detect guest on app startup**

In `LoginVM.ets` or `EntryAbility.ets`, check if userType is 'guest' on startup:

```typescript
// LoginVM.ets
static checkGuestMode(): boolean {
  const userType = AuthCache.getUserType()
  return userType === 'guest'
}
```

- [ ] **Step 2: When userType is 'guest', skip cloud sync**

In `Sync.ets` or wherever sync is triggered:

```typescript
// Sync.ets — modify push/pull
if (AuthCache.getUserType() === 'guest') {
  // Local-only mode: skip network sync
  return Promise.resolve({ code: 0, data: { updated: [], deleted: [] } })
}
```

- [ ] **Step 3: Show local-only indicator in UI**

In `MineView.ets` or wherever user info displays:

```typescript
// When isGuest mode, show badge or text: "本地模式"
if (LoginUtil.checkGuestMode()) {
  Text('本地模式')
    .fontSize($r('sys.float.Body_S'))
    .fontColor($r('sys.color.font_secondary'))
}
```

- [ ] **Step 4: Commit**

```bash
git add features/mine/src/main/ets/
git commit -m "feat: add guest mode detection and local-only indicator"
```

---

### Task 6: Frontend — Guest to Full Account Upgrade

**Files:**
- Modify: `features/mine/src/main/ets/views/MineView.ets`
- Modify: `features/mine/src/main/ets/viewmodels/EditProfileVM.ets`
- Modify: `moneytrack-api/src/routes/auth.js` — add /upgrade endpoint

- [ ] **Step 1: Backend — add /upgrade endpoint**

```javascript
// auth.js — POST /upgrade
router.post('/upgrade', authMiddleware, async (req, res) => {
  const { username, password } = req.body;

  if (req.userType !== 'guest') {
    return res.status(400).json({ code: 400, msg: 'User is not a guest' });
  }

  if (!username || !password) {
    return res.status(400).json({ code: 400, msg: 'Username and password are required' });
  }

  try {
    const user = await userService.upgradeGuestUser(req.userId, username, password);
    const { accessToken, refreshToken } = generateTokens(user.id);
    res.json({ code: 0, data: { user, accessToken, refreshToken } });
  } catch (err) {
    res.status(400).json({ code: 400, msg: err.message });
  }
});
```

Add `upgradeGuestUser` to `userService.js`:

```javascript
async function upgradeGuestUser(userId, username, password) {
  const db = await getDb();
  const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);
  const now = new Date().toISOString();

  const stmt = db.prepare(
    'UPDATE users SET username = ?, password = ?, userType = ?, updatedAt = ? WHERE id = ? AND deleted = 0'
  );
  stmt.run([username, hashedPassword, 'full', now, userId]);
  stmt.free();
  await saveDbAsync();

  return findById(userId);
}
```

- [ ] **Step 2: Frontend — add upgrade button in MineView**

When `isGuest` is true, show button "升级到完整账号":

```typescript
// MineView.ets
Button('升级到完整账号')
  .onClick(() => {
    // Open dialog with username + password fields
    // Call AuthApis.upgrade() → POST /api/auth/upgrade
    // On success: update AuthCache, set userType to 'full', show success toast
  })
```

- [ ] **Step 3: Add upgrade API to Auth.ets**

```typescript
// Auth.ets
public upgrade(params: { username: string; password: string }): Promise<BaseResponse> {
  return request.post(RequestUrlMap.AUTH_UPGRADE, params)
}
```

Add `AUTH_UPGRADE = 'auth/upgrade'` to `Enums.ets`.

- [ ] **Step 4: Commit**

```bash
git add moneytrack-api/src/
git add commons/lib_network/src/main/ets/
git add features/mine/src/main/ets/
git commit -m "feat: add guest to full account upgrade flow"
```

---

## Verification

After all tasks, verify:
1. Can register with username+password (no email)
2. Can login with username+password
3. Guest account created with local-only flag
4. Guest user sees "本地模式" indicator
5. Guest user cannot sync to cloud
6. Guest can upgrade to full account with username+password
7. After upgrade, userType becomes 'full' and sync works

---

## Execution Options

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?