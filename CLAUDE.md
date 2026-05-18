# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **HarmonyOS**记账 (expense tracking) application template. Target: HarmonyOS 6.0.0+, DevEco Studio 6.0.0+.

**Current state**: Local-only SQLite storage. No backend connected. Network layer (`commons/lib_network`) exists but only contains mock/stub code.

## Build & Run

- **DevEco Studio**: `Run > Run 'entry'` or `Debug 'entry'`
- **CLI build**: `hvigor` (Gradle-like, configured in `hvigor/hvigor-config.json5`)
- **Sign tooling**: AppGallery Connect required for client ID, in-app payments need merchant service activation

## Architecture

### 4-Layer Structure (products → features → components → commons)

```
products/entry      # Device entry layer (MainEntry.ets)
features/           # Feature modules (home, assets, statistics, mine)
components/         # Reusable UI components (bill_card, asset_manage, etc.)
commons/            # Shared utilities (commonlib, lib_network)
```

### Key Modules

| Module | Purpose |
|--------|---------|
| `bill_data_processing` | Database access (`AccountingDB`), data types, SQLite operations |
| `commonlib` | Router, logger, user info utilities |
| `lib_network` | HTTP client (`@ohos/axios`), API types, mock endpoints |
| `bill_base` / `asset_base` | Shared constants, enums, logger for bill/asset domains |

### Database Layer (`bill_data_processing/src/main/ets/utils/accountingdb/`)

- `AccountingDB` extends `BaseDB` from `basedb/`
- 4 tables: `accounts`, `transactions`, `assets`, `budgets`
- All DB ops go through `AccountingDB` singleton (`accountingDB`)
- Transaction support via `this.transaction(fn)`
- Default account auto-created on init

### Network Layer

- `lib_network/src/main/ets/https/` contains `Request` class (axios wrapper)
- `lib_network/src/main/ets/types/` contains request/response interfaces
- **Not yet connected to real backend** — only mock data

### Router

- `commonlib/src/main/ets/utils/router/` — `RouterModule`, `RouterMap`, `DialogMap`
- Navigation via `router.pushUrl()` / `router.replaceUrl()`
- Dialogs via `RouterModule.openDialog()`

## Adding Cloud Sync

The user plans to add a backend. Key changes needed:

1. **API endpoints** → add to `lib_network/src/main/ets/https/`
2. **Auth** → `aggregated_login` component handles Huawei login; backend auth token needs storage
3. **Data sync** → `AccountingDB` operations should be mirrored to cloud API
4. **Network module config** → update `module.json5` if adding new permissions

## HarmonyOS Specifics

- **ArkTS** (TypeScript-like) — `.ets` files
- **relationalStore** for SQLite — async API, StoreConfig per DB
- **@ohos/axios** for HTTP requests
- **@ohos/mpchart** for charts (pie, bar, line, radar)
- **UI components**: Flex, Column, Row, List, NavDestination, Tabs
- **Permissions**: `ohos.permission.INTERNET` declared in `module.json5`

## File Organization

- Small files preferred — many under 200 lines
- Components organized by domain: `bill_*`, `asset_*`, `aggregated_*`
- Each module has `src/main/ets/views/` for pages, `src/main/ets/utils/` for utilities
- Tests in `src/ohosTest/` per module

## Common Patterns

- Singleton pattern for DB access: `const accountingDB = new AccountingDB(); export { accountingDB }`
- DB operations return Promises, use `async/await`
- UI state via `@State`, `@Link`, `@Prop` decorators
- Router params passed via `Want` parameters

## Dependencies

Core packages in `oh_modules/.ohpm/`:
- `@hw-agconnect/ui-toast`, `@hw-agconnect/ui-dialog` — Toast and dialog components
- `@hw-agconnect/axios-mock-adapter` — API mocking
- `@ohos/axios` — HTTP client
- `@ohos/mpchart` — charting library
- `dayjs` — date formatting
- `lunar` — Chinese lunar calendar