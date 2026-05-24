# Auth Token Validation on App Startup

**Goal:** Validate stored auth token on app startup; if invalid, clear login state to prevent authenticated actions with orphaned users.

**Architecture:** On `EntryAbility.onWindowStageCreate`, check for stored token and call `AuthApis.me()`. If call fails or returns error code, call `AuthCache.clear()` and set `iData.global.isLogin = false`.

**Tech Stack:** ArkTS, `@ohos/axios`, HarmonyOS EntryAbility lifecycle

---

## Task 1: Add token validation to EntryAbility

**Files:**
- Modify: `products/entry/src/main/ets/entryability/EntryAbility.ets:24-35`

**Steps:**

- [ ] **Step 1: Read current EntryAbility.ets to understand existing structure**

Run: (Read tool) `products/entry/src/main/ets/ability/EntryAbility.ets`

- [ ] **Step 2: Add imports and `validateAuth` method to EntryAbility.ets**

```typescript
import { AuthCache } from 'commonlib';
import { AuthApis } from 'lib_network';
import { iData } from 'commonlib';

// In EntryAbility class, add:
async validateAuth(): Promise<void> {
  const token = AuthCache.getAccessToken();
  if (!token) {
    return;
  }
  try {
    const res = await AuthApis.me();
    if (res.code !== 0) {
      this.clearAuthState();
    }
  } catch {
    this.clearAuthState();
  }
}

clearAuthState(): void {
  AuthCache.clear();
  iData.global.isLogin = false;
}
```

- [ ] **Step 3: Call `validateAuth()` from `onWindowStageCreate`**

In `onWindowStageCreate(windowStage)` at line 24, add before `Logger.info(TAG, 'Ability onWindowStageCreate')`:
```typescript
this.validateAuth();
```

- [ ] **Step 4: Build to verify no errors**

Run: `hvigor assembleHap` or DevEco Studio build

Expected: BUILD SUCCESSFUL

- [ ] **Step 5: Commit**

```bash
git add products/entry/src/main/ets/ability/EntryAbility.ets
git commit -m "feat: validate auth token on app startup"
```