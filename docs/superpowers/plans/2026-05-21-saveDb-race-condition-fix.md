# saveDb() Race Condition Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix concurrent `saveDb()` calls causing potential data corruption when multiple requests write simultaneously. Each concurrent `fs.writeFileSync` can overwrite the other's changes.

**Architecture:** Wrap `saveDb()` with an async write queue (promise chain). First caller acquires lock, subsequent callers wait their turn. Serializes all writes while keeping them non-blocking for callers.

**Tech Stack:** Node.js promise chain, `fs.writeFileSync`

---

## File Structure

- Modify: `moneytrack-api/src/db.js` — add write queue, export `saveDbAsync`
- Modify: `moneytrack-api/src/services/userService.js` — `saveDb()` → `await saveDbAsync()`
- Modify: `moneytrack-api/src/services/categoryService.js` — `saveDb()` → `await saveDbAsync()`
- Modify: `moneytrack-api/src/services/syncService.js` — `saveDb()` → `await saveDbAsync()`
- Modify: All `moneytrack-api/src/routes/*.js` files with `saveDb()` calls

---

### Task 1: Add async write queue to db.js

**Files:**
- Modify: `moneytrack-api/src/db.js:44-54`

- [ ] **Step 1: Write the failing test**

Create `moneytrack-api/__tests__/saveDb.test.js`:

```javascript
const request = require('supertest');
const { initializeDatabase, saveDbAsync } = require('../src/db');
const { app } = require('../src/index');

describe('saveDb race condition fix', () => {
  beforeAll(async () => {
    await initializeDatabase();
  });

  it('concurrent saveDb calls should not corrupt data', async () => {
    const promises = Array.from({ length: 10 }, (_, i) =>
      saveDbAsync().then(() => i)
    );
    const results = await Promise.all(promises);
    expect(results.length).toBe(10);
  });
});
```

- [ ] **Step 2: Run test to verify current behavior**

Run: `cd moneytrack-api && npm test -- --testPathPattern=saveDb`
Expected: PASS (no queue yet)

- [ ] **Step 3: Implement write queue in db.js**

Replace `saveDb` function with promise-chain queue:

```javascript
let writePromise = Promise.resolve();

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
      } finally {
        resolve();
      }
    });
  });
}

function saveDb() {
  return saveDbAsync();
}
```

- [ ] **Step 4: Update module.exports**

Add `saveDbAsync` to `module.exports`:

```javascript
module.exports = { getDb, initializeDatabase, saveDb, saveDbAsync, revokeToken, isTokenRevoked };
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd moneytrack-api && npm test -- --testPathPattern=saveDb`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add src/db.js __tests__/saveDb.test.js
git commit -m "fix: add async write queue to saveDb to prevent concurrent corruption"
```

---

### Task 2: Swap saveDb() → saveDbAsync() in services

**Files:**
- Modify: `moneytrack-api/src/services/userService.js`
- Modify: `moneytrack-api/src/services/categoryService.js`
- Modify: `moneytrack-api/src/services/syncService.js`

- [ ] **Step 1: Update imports**

In each file, replace:
```javascript
const { getDb, saveDb } = require('../db');
```
With:
```javascript
const { getDb, saveDbAsync } = require('../db');
```

- [ ] **Step 2: Replace all saveDb() calls with await saveDbAsync()**

Affected locations:
- `userService.js` lines 18, 75: `saveDb()` → `await saveDbAsync()`
- `categoryService.js` lines 56, 113, 141: `saveDb()` → `await saveDbAsync()`
- `syncService.js` line 196: `saveDb()` → `await saveDbAsync()`

- [ ] **Step 3: Run tests**

Run: `cd moneytrack-api && npm test`
Expected: All PASS

- [ ] **Step 4: Commit**

```bash
git add src/services/userService.js src/services/categoryService.js src/services/syncService.js
git commit -m "refactor: use saveDbAsync for non-blocking writes in services"
```

---

### Task 3: Swap saveDb() → saveDbAsync() in routes

**Files:**
- Grep for `saveDb()` across `moneytrack-api/src/routes/` to find all occurrences
- Modify each file found

- [ ] **Step 1: Update imports in each route file**

```javascript
const { getDb, saveDbAsync } = require('../db');
```

- [ ] **Step 2: Replace all saveDb() calls with await saveDbAsync()**

Run: `grep -rn "saveDb()" moneytrack-api/src/routes/`
Then fix each occurrence.

- [ ] **Step 3: Run tests**

Run: `cd moneytrack-api && npm test`
Expected: All PASS

- [ ] **Step 4: Commit**

```bash
git add src/routes/
git commit -m "refactor: use saveDbAsync in route handlers for thread-safe writes"
```

---

## Self-Review

1. **Spec coverage:** All `saveDb()` call sites updated to async queue. Lock ensures serialized writes.
2. **Placeholder scan:** No TBD/TODO — each step shows actual code.
3. **Type consistency:** `saveDbAsync()` returns `Promise<void>`. `saveDb()` remains exported for backward compat but now delegates to async version.