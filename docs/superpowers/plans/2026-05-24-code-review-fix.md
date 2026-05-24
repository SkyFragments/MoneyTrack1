# Code Review Findings Fix — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all confirmed bugs from 5-angle code review + database schema audit; push PR and merge to master.

**Architecture:** Isolated `fix/code-review-findings` branch already exists locally with partial fixes. Remaining issues split into: (A) AuthCache/Logout state cleanup, (B) Database schema alignment frontend↔backend, (C) Minor fixes. Each task is self-contained and can be committed independently.

**Tech Stack:** ArkTS (HarmonyOS), Node.js/sql.js backend, relationalStore (frontend SQLite)

---

## Task 0: Verify current branch state

- [ ] **Step 1: Check branch status**

Run: `git log --oneline -3`
Expected: Latest commit is the partial "registerUser + validation toasts" fix

- [ ] **Step 2: Verify partial fix already applied**

Run: `grep -n "AuthCache.setUserType" features/mine/src/main/ets/viewmodels/LoginVM.ets`
Expected: Line with `AuthCache.setUserType('full')` inside `registerUser` function

---

## Task 1: AuthCache logout cleanup

**Files:**
- Modify: `components/aggregated_login/src/main/ets/viewmodel/AggregatedLoginVM.ets`
- Modify: `commons/commonlib/src/main/ets/utils/auth/AuthCache.ets`
- Modify: `features/mine/src/main/ets/viewmodels/LoginVM.ets` (handleRegister, handleUpgrade)

- [ ] **Step 1: Add AuthCache.clear() method**

Modify: `commons/commonlib/src/main/ets/utils/auth/AuthCache.ets`

Add `clear()` method to `AuthCacheModel` class that resets all fields to defaults:

```typescript
clear(): void {
  this.accessToken = '';
  this.refreshToken = '';
  this.userId = '';
  this.userType = null;
  this.phoneNumber = '';
}
```

Also add static `clear()` to the `AuthCache` namespace:

```typescript
static clear(): void {
  AuthCacheModel.getInstance().clear();
}
```

- [ ] **Step 2: clearInstance calls AuthCache.clear()**

Modify: `components/aggregated_login/src/main/ets/viewmodel/AggregatedLoginVM.ets:75`

Add after `this._instance = null`:

```typescript
AuthCache.clear();
iData.global.isLogin = false;
```

- [ ] **Step 3: resetInstance also clears isLogin**

Modify: `components/aggregated_login/src/main/ets/viewmodel/AggregatedLoginVM.ets:79`

Add at end of `resetInstance()`:

```typescript
iData.global.isLogin = false;
```

- [ ] **Step 4: handleRegister clears AuthCache before setTokens**

Modify: `features/mine/src/main/ets/viewmodels/LoginVM.ets:205`

Add before `AuthCache.setTokens` in `handleRegister`:

```typescript
AuthCache.clear(); // prevent residual guest tokens contaminating new session
```

- [ ] **Step 5: handleUpgrade same cleanup**

Modify: `features/mine/src/main/ets/viewmodels/LoginVM.ets:246`

Add same `AuthCache.clear()` before `AuthCache.setTokens` in `handleUpgrade`.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "fix: clear AuthCache + isLogin on logout/register-upgrade"
```

---

## Task 2: Database schema alignment — backend adds missing columns

**Files:**
- Modify: `moneytrack-api/src/db.js`

- [ ] **Step 1: Add balance to accounts table**

Modify: `moneytrack-api/src/db.js` — find `CREATE TABLE IF NOT EXISTS accounts` and add `balance REAL DEFAULT 0` column after `type TEXT NOT NULL`.

- [ ] **Step 2: Add createdAt/updatedAt to accounts table**

Add `createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL` to accounts CREATE TABLE.

- [ ] **Step 3: Add localId to transactions table**

Add `localId INTEGER` column to transactions table (for client-generated ID tracking).

- [ ] **Step 4: Change excluded to INTEGER in transactions**

Modify: `excluded INTEGER DEFAULT 0` (not BOOLEAN) in transactions table.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "fix: align db schema — add balance, timestamps, localId, fix excluded type"
```

---

## Task 3: Database schema alignment — frontend adds missing columns

**Files:**
- Modify: `components/bill_data_processing/src/main/ets/utils/accountingdb/Constants.ets`

- [ ] **Step 1: Add deleted column to all 4 frontend tables**

For each of `ACCOUNT_TABLE_SQL_CREATE`, `TRANSACTION_TABLE_SQL_CREATE`, `ASSET_TABLE_SQL_CREATE`, `BUDGET_TABLE_SQL_CREATE` — add `deleted INTEGER DEFAULT 0` before the closing `)`.

- [ ] **Step 2: Add localId to transactions**

Add `localId INTEGER` to `TRANSACTION_TABLE_SQL_CREATE`.

- [ ] **Step 3: Add createdAt/updatedAt to accounts**

Add `createdAt TEXT NOT NULL DEFAULT ''`, `updatedAt TEXT NOT NULL DEFAULT ''` to `ACCOUNT_TABLE_SQL_CREATE`.

- [ ] **Step 4: Change excluded to INTEGER**

Change `excluded BOOLEAN DEFAULT true` → `excluded INTEGER DEFAULT 0` in `TRANSACTION_TABLE_SQL_CREATE`.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "fix: align frontend schema — add deleted, localId, timestamps columns"
```

---

## Task 4: Fix BudgetTableBasis id vs budgetId mismatch

**Files:**
- Modify: `components/bill_data_processing/src/main/ets/utils/accountingdb/Types.ets`

- [ ] **Step 1: Add budgetId field to BudgetTableBasis**

Modify: `BudgetTableBasis` interface in `Types.ets` — change `id: string` to `budgetId: string` (to match backend syncService alias).

- [ ] **Step 2: Update all BudgetTableBasis usages**

Grep for `budget\.id` and `BudgetTableBasis` throughout `bill_data_processing/` — replace `budget.id` with `budget.budgetId`.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "fix: BudgetTableBasis uses budgetId to match backend alias"
```

---

## Task 5: Sync.ets — fix guest stub serverTime type

**Files:**
- Modify: `commons/lib_network/src/main/ets/https/apis/Sync.ets`

- [ ] **Step 1: Change serverTime from '' to 0**

Find guest-mode early return and change `serverTime: ''` to `serverTime: 0`.

- [ ] **Step 2: Commit**

```bash
git add -A && git commit -m "fix: Sync.ets guest stub uses serverTime:0 instead of empty string"
```

---

## Task 6: doSync — add transaction null guard and push

**Files:**
- Modify: `features/mine/src/main/ets/viewmodels/MineVM.ets`

- [ ] **Step 1: Add transaction field validation**

Wrap transaction fields in null checks:

```typescript
for (const tx of (data.transactions || [])) {
  if (tx.accountId == null || tx.type == null) {
    continue; // skip malformed records
  }
  await AccountingDB.addTransaction({
    accountId: tx.accountId,
    type: tx.type as BalanceChangeType,
    resource: tx.resource ?? '',
    amount: tx.amount ?? 0,
    date: tx.date ?? new Date().toISOString(),
    note: tx.note ?? '',
    excluded: tx.excluded ?? false,
    assetId: tx.assetId ?? '',
  });
}
```

- [ ] **Step 2: Commit**

```bash
git add -A && git commit -m "fix: doSync validates transaction fields and skips malformed records"
```

---

## Task 7: Final verification + push PR

- [ ] **Step 1: Run all commits into one clean branch**

Run: `git log --oneline`
Expected: 4-5 commits (partial fix + Task 1 + Task 2 + Task 3 + Task 4 + Task 5 + Task 6)

- [ ] **Step 2: Rebase into single commit**

```bash
git rebase -i HEAD~7  # squash all into one
```

- [ ] **Step 3: Push and create PR**

```bash
git push origin fix/code-review-findings --force
gh pr create --title "fix: code review findings — auth/sync/schema corrections" --body "...
```

- [ ] **Step 4: Merge PR**

```bash
gh pr merge --squash
```

---