import { relationalStore } from '@kit.ArkData';

export class AccountingDBConstants {
  public static readonly DB_CONFIG: relationalStore.StoreConfig = {
    name: 'AccountingApp.db',
    securityLevel: relationalStore.SecurityLevel.S1,
    encrypt: false,
  };
  public static readonly ACCOUNT_TABLE_NAME: string = 'accounts';
  public static readonly ACCOUNT_TABLE_SQL_CREATE: string = `CREATE TABLE IF NOT EXISTS accounts (
    accountId INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    type TEXT NOT NULL CHECK(type IN ('default', 'custom')),
    date TEXT DEFAULT '01',
    accountIncome REAL DEFAULT 0,
    accountExpense REAL DEFAULT 0,
    balance REAL DEFAULT 0
  )`;
  public static readonly ACCOUNT_TABLE_INDEXES_CREATE: string[] = [
    'CREATE INDEX IF NOT EXISTS index_type ON accounts (type)',
  ];
  public static readonly TRANSACTION_TABLE_NAME: string = 'transactions';
  public static readonly TRANSACTION_TABLE_SQL_CREATE: string = `CREATE TABLE IF NOT EXISTS transactions (
    transactionId INTEGER PRIMARY KEY AUTOINCREMENT,
    accountId INTEGER NOT NULL,
    assetId INTEGER DEFAULT NULL,
    type TEXT CHECK(type IN ('income', 'expense')),
    resource INTEGER NOT NULL,
    amount REAL NOT NULL,
    date TEXT NOT NULL,
    note TEXT DEFAULT '',
    excluded BOOLEAN DEFAULT true,
    FOREIGN KEY (accountId) REFERENCES accounts(accountId) ON DELETE CASCADE,
    FOREIGN KEY (assetId) REFERENCES assets(assetId) ON DELETE CASCADE
  )`;
  public static readonly TRANSACTION_TABLE_INDEXES_CREATE: string[] = [
    'CREATE INDEX IF NOT EXISTS index_type ON transactions (type)',
    'CREATE INDEX IF NOT EXISTS index_resource ON transactions (resource)',
    'CREATE INDEX IF NOT EXISTS index_date ON transactions (date)',
  ];
  public static readonly ASSET_TABLE_NAME: string = 'assets';
  public static readonly ASSET_TABLE_SQL_CREATE: string = `CREATE TABLE IF NOT EXISTS assets (
    assetId INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT DEFAULT '',
    type INTEGER CHECK(type IN (1, 2, 3)),
    subType INTEGER NOT NULL,
    category INTEGER NOT NULL CHECK(category IN (1, 2)),
    amount REAL NOT NULL DEFAULT 0,
    note TEXT DEFAULT '',
    isCustom BOOLEAN DEFAULT false
  )`;
  public static readonly ASSET_TABLE_INDEXES_CREATE: string[] = [
    'CREATE INDEX IF NOT EXISTS index_type ON assets (type)',
    'CREATE INDEX IF NOT EXISTS index_subType ON assets (subType)',
  ];
  public static readonly BUDGET_TABLE_NAME: string = 'budgets';
  public static readonly BUDGET_TABLE_SQL_CREATE: string = `CREATE TABLE IF NOT EXISTS budgets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    accountId INTEGER NOT NULL,
    month TEXT NOT NULL,
    amount REAL NOT NULL DEFAULT 0,
    FOREIGN KEY (accountId) REFERENCES accounts(accountId) ON DELETE CASCADE,
    UNIQUE(accountId, month)
  )`;
  public static readonly BUDGET_TABLE_INDEXES_CREATE: string[] = [
    'CREATE INDEX IF NOT EXISTS index_budget_account_month ON budgets (accountId, month)'
  ];
}
