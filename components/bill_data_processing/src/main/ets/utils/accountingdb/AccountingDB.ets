import { ToastDialog } from '@hw-agconnect/ui-toast';
import relationalStore from '@ohos.data.relationalStore';
import { AssetSummary, TransactionImpact } from 'asset_base';
import { AccountType, Logger } from 'bill_base';
import { BaseDB } from '../basedb/BaseDB';
import { DBOperator } from '../basedb/Constants';
import {
  TableOrderByParams,
  TablePredicateParams,
  TableQueryWithPaginationRsp,
  TableSchema,
} from '../basedb/Types';
import { AccountingDBConstants } from './Constants';
import {
  AccountTableFields,
  TransactionTableFields,
  AssetTableFields,
} from './Enums';
import {
  AccountTableBasis,
  AmountSummary,
  AssetReport,
  AssetTableBasis,
  TransactionReportRsp,
  TransactionTableBasis,
  UserAsset,
  UserTablePredicateParams,
  UserTransaction,
  BudgetTableBasis,
  BillInfo,
  MinAccountId
} from './Types';

const TAG = '[AccountingDB]';

class AccountingDB extends BaseDB {
  protected dbConfig: relationalStore.StoreConfig =
    AccountingDBConstants.DB_CONFIG;
  protected tableSchemas: TableSchema[] = [
    {
      tableName: AccountingDBConstants.ACCOUNT_TABLE_NAME,
      createSQL: AccountingDBConstants.ACCOUNT_TABLE_SQL_CREATE,
      indexes: AccountingDBConstants.ACCOUNT_TABLE_INDEXES_CREATE,
    },
    {
      tableName: AccountingDBConstants.TRANSACTION_TABLE_NAME,
      createSQL: AccountingDBConstants.TRANSACTION_TABLE_SQL_CREATE,
      indexes: AccountingDBConstants.TRANSACTION_TABLE_INDEXES_CREATE,
    },
    {
      tableName: AccountingDBConstants.ASSET_TABLE_NAME,
      createSQL: AccountingDBConstants.ASSET_TABLE_SQL_CREATE,
      indexes: AccountingDBConstants.ASSET_TABLE_INDEXES_CREATE,
    },
    {
      tableName: AccountingDBConstants.BUDGET_TABLE_NAME,
      createSQL: AccountingDBConstants.BUDGET_TABLE_SQL_CREATE,
      indexes: AccountingDBConstants.BUDGET_TABLE_INDEXES_CREATE,
    },
  ];

  public async initialize(context: Context) {
    await super.initialize(context);
    await this._initDefaultAccounts();
  }

  // 初始化账本
  private async _initDefaultAccounts() {
    const existing = await this.query<AccountTableBasis>(
      AccountingDBConstants.ACCOUNT_TABLE_NAME,
      [
        {
          field: AccountTableFields.TYPE,
          operator: DBOperator.EQUAL,
          value: AccountType.DEFAULT,
        }
      ],
    );

    if (existing.length === 0) {
      const accountTable: AccountTableBasis = {
        accountId: new Date().getTime(),
        name: '默认账本',
        type: AccountType.DEFAULT,
        date: '01',
        accountIncome: 0,
        accountExpense: 0,
      };
      await this.insert(AccountingDBConstants.ACCOUNT_TABLE_NAME, accountTable);
      Logger.info(TAG, 'create default account table success');
    }
  }

  // 新增账本
  public async addAccount(account: AccountTableBasis) {
    return this.transaction(async () => {
      try {
        if (account.type === AccountType.DEFAULT) {
          const newAccountId = await this.insert(AccountingDBConstants.ACCOUNT_TABLE_NAME, account);

          if (newAccountId > 0) {
            const updateSql = `UPDATE accounts SET type = 'custom' WHERE type = 'default' AND accountId != ${newAccountId}`;
            await this.executeSql(updateSql);

            ToastDialog.showToast({ message: '账本新增成功~' });
            Logger.info(TAG, 'insert account success.');
          }
        } else {
          const res = await this.insert(AccountingDBConstants.ACCOUNT_TABLE_NAME, account);
          if (res > 0) {
            ToastDialog.showToast({ message: '账本新增成功~' });
          }
        }
      } catch (err) {
        ToastDialog.showToast({ message: '账本新增失败，请稍后重试~' });
        Logger.error(TAG, 'insert account failed. error:' + JSON.stringify(err));
      }
    });
  }

  // 删除账本
  public async deleteAccount(accountId: number) {
    const condition: TablePredicateParams = {
      field: AccountTableFields.ACCOUNT_ID,
      value: accountId,
      operator: DBOperator.EQUAL,
    };
    try {
      const allAccounts = await this.query<AccountTableBasis>(
        AccountingDBConstants.ACCOUNT_TABLE_NAME,
        []
      );
      if (allAccounts.length <= 1) {
        throw new Error('Must keep at least one account');
      }
      await this.delete(AccountingDBConstants.ACCOUNT_TABLE_NAME, [condition]);
      ToastDialog.showToast({ message: '账本删除成功~' });
      Logger.info(TAG, 'delete account success.');
    } catch (err) {
      ToastDialog.showToast({ message: '账本删除失败，请稍后重试~' });
      Logger.error(TAG, 'delete account failed. error:' + JSON.stringify(err));
    }
  }

  // 编辑账本
  public async editAccount(account: AccountTableBasis) {
    const condition: TablePredicateParams = {
      field: AccountTableFields.ACCOUNT_ID,
      value: account.accountId,
      operator: DBOperator.EQUAL,
    };
    return this.transaction(async () => {
      try {
        const oldAccounts = await this.query<AccountTableBasis>(
          AccountingDBConstants.ACCOUNT_TABLE_NAME,
          [condition]
        );
        if (oldAccounts.length === 0) {
          throw new Error('Account not found');
        }
        const oldAccount = oldAccounts[0];
        if (account.type === AccountType.DEFAULT) {
          const updateOthersSql =
            `UPDATE accounts SET type = 'custom' WHERE type = 'default' AND accountId != ${account.accountId}`;
          await this.executeSql(updateOthersSql);
        }
        if (account.type === AccountType.CUSTOM && oldAccount.type === AccountType.DEFAULT) {
          const allAccounts = await this.query<AccountTableBasis>(
            AccountingDBConstants.ACCOUNT_TABLE_NAME,
            [],
            { field: AccountTableFields.ACCOUNT_ID, desc: true }
          );
          const otherAccounts = allAccounts.filter(a => a.accountId !== account.accountId);
          if (otherAccounts.length <= 0) {
            throw new Error('Must keep at least one default account');
          }
          const nextDefaultAccount = otherAccounts[0];
          const updateNextSql = `UPDATE accounts SET type = 'default' WHERE accountId = ${nextDefaultAccount.accountId}`;
          await this.executeSql(updateNextSql);
        }
        const res = await this.update<AccountTableBasis>(
          AccountingDBConstants.ACCOUNT_TABLE_NAME,
          account,
          [condition],
        );
        if (res === 1) {
          ToastDialog.showToast({ message: '账本更新成功~' });
          Logger.info(TAG, 'update account success.');
        } else {
          throw new Error(res.toString());
        }
      } catch (err) {
        const errMsg = err instanceof Error ? err.message : JSON.stringify(err);
        if (errMsg === 'Must keep at least one default account') {
          ToastDialog.showToast({ message: '至少保留一个默认账本' });
        } else {
          ToastDialog.showToast({ message: '账本更新失败，请稍后重试~' });
        }
        Logger.error(TAG, 'update account failed. error:' + errMsg);
      }
    });
  }

  // 获取账本列表
  public async getAccounts(): Promise<AccountTableBasis[]> {
    try {
      // 排序
      const sql = `
        SELECT *,
        (SELECT COUNT(*) FROM transactions WHERE transactions.accountId = accounts.accountId) as transactionCount
        FROM accounts
        ORDER BY type ASC, accountId DESC
      `;
      return await this.querySql<AccountTableBasis>(sql);
    } catch (err) {
      Logger.error(TAG, 'get accounts failed. error:' + JSON.stringify(err));
      return [];
    }
  }

  // 根据交易数据更新账本统计
  private async _updateAccountStats(accountId: number) {
    const sql = `
      UPDATE accounts
      SET accountIncome = (
        SELECT COALESCE(SUM(amount), 0)
        FROM transactions
        WHERE accountId = ${accountId} AND type = 'income'
      ),
      accountExpense = (
        SELECT COALESCE(SUM(amount), 0)
        FROM transactions
        WHERE accountId = ${accountId} AND type = 'expense'
      )
      WHERE accountId = ${accountId}
    `;
    await this.executeSql(sql);
  }

  // 获取默认账本的ID
  private async _getDefaultAccountId(): Promise<number> {
    try {
      const accounts = await this.query<AccountTableBasis>(
        AccountingDBConstants.ACCOUNT_TABLE_NAME,
        [{ field: AccountTableFields.TYPE, operator: DBOperator.EQUAL, value: AccountType.DEFAULT }]
      );
      if (accounts.length > 0) {
        return accounts[0].accountId;
      }
    } catch (err) {
      Logger.error(TAG, 'get default account id failed.' + JSON.stringify(err));
    }
    return 0;
  }

  // 新增交易记录
  public async addTransaction(userTx: UserTransaction): Promise<void> {
    const tx: TransactionTableBasis = {
      transactionId: new Date().getTime(),
      accountId: userTx.accountId,
      type: userTx.type,
      resource: userTx.resource,
      amount: userTx.amount,
      date: userTx.date,
      note: userTx.note,
      excluded: userTx.excluded,
      assetId: userTx.assetId,
    };
    return this.transaction(async () => {
      try {
        await this.insert(AccountingDBConstants.TRANSACTION_TABLE_NAME, tx);
        ToastDialog.showToast({ message: '交易记录新增成功~' });
        await this.updateAssetAccountFromTransaction(userTx);
        await this._updateAccountStats(userTx.accountId);
        Logger.info(TAG, 'insert transaction success.');
      } catch (err) {
        ToastDialog.showToast({ message: '交易记录新增失败，请稍后重试~' });
        Logger.error(
          TAG,
          'insert transaction failed. error:' + JSON.stringify(err),
        );
      }
    });
  }

  // 删除交易记录
  public async deleteTransactions(transactionId: number) {
    const condition: TablePredicateParams = {
      field: TransactionTableFields.TRANSACTION_ID,
      value: transactionId,
      operator: DBOperator.EQUAL,
    };

    return this.transaction(async () => {
      try {
        const txList = await this.query<TransactionTableBasis>(
          AccountingDBConstants.TRANSACTION_TABLE_NAME,
          [condition]
        );
        if (txList.length === 0) {
          Logger.warn(TAG, 'Transaction not found, nothing to delete.');
          return;
        }
        const tx = txList[0];
        await this.delete(AccountingDBConstants.TRANSACTION_TABLE_NAME, [condition]);
        if (tx.accountId) {
          await this._updateAccountStats(tx.accountId);
        }
        if (tx.assetId) {
          const isExpense = tx.type === 'expense';
          const sign = isExpense ? 1 : -1;
          const sql = `
            UPDATE assets
            SET amount = amount + (${sign} * ${tx.amount})
            WHERE assetId = ${tx.assetId}
          `;
          await this.executeSql(sql);
        }
        ToastDialog.showToast({ message: '删除成功~' });
        Logger.info(TAG, 'delete transaction success.');
      } catch (err) {
        ToastDialog.showToast({ message: '交易记录删除失败，请稍后重试~' });
        Logger.error(TAG, 'delete transaction failed. error:' + JSON.stringify(err));
      }
    });
  }

  // 删除相同类型的所有交易记录
  public async deleteTransactionsByResource(resource: number) {
    const condition: TablePredicateParams = {
      field: TransactionTableFields.RESOURCE,
      value: resource,
      operator: DBOperator.EQUAL,
    };
    try {
      const res = await this.delete(
        AccountingDBConstants.TRANSACTION_TABLE_NAME,
        [condition],
      );
      Logger.info(TAG, 'delete transaction success.');
      return res;
    } catch (err) {
      ToastDialog.showToast({ message: '交易记录删除失败，请稍后重试~' });
      Logger.error(
        TAG,
        'delete transaction failed. error:' + JSON.stringify(err),
      );
      return 0;
    }
  }

  // 更新交易记录
  public async updateTransactions(userTx: TransactionTableBasis) {
    const condition: TablePredicateParams = {
      field: TransactionTableFields.TRANSACTION_ID,
      value: userTx.transactionId,
      operator: DBOperator.EQUAL,
    };
    return this.transaction(async () => {
      try {
        const oldTxList = await this.query<TransactionTableBasis>(
          AccountingDBConstants.TRANSACTION_TABLE_NAME,
          [condition]
        );

        if (oldTxList.length === 0) {
          throw new Error('Transaction not found');
        }
        const oldTx = oldTxList[0];
        const res = await this.update<TransactionTableBasis>(
          AccountingDBConstants.TRANSACTION_TABLE_NAME,
          userTx,
          [condition],
        );
        if (res === 1) {
          await this._updateAccountStats(userTx.accountId);
          const getImpact = (type: string, amount: number) => type === 'expense' ? -amount : amount;

          const oldImpact = getImpact(oldTx.type, oldTx.amount);
          const newImpact = getImpact(userTx.type, userTx.amount);
          const diff = newImpact - oldImpact;
          if (diff !== 0 && userTx.assetId) {
            const sql = `
              UPDATE assets
              SET amount = amount + ${diff}
              WHERE assetId = ${userTx.assetId}
            `;
            await this.executeSql(sql);
          } else if (oldTx.assetId && oldTx.assetId !== userTx.assetId) {
            Logger.warn(TAG, 'AssetId changed, complex balance update needed');
          }
          ToastDialog.showToast({ message: '交易记录更新成功~' });
          Logger.info(TAG, 'update transaction success.');
        } else {
          throw new Error(res.toString());
        }
      } catch (err) {
        ToastDialog.showToast({ message: '交易记录更新失败，请稍后重试~' });
        Logger.error(TAG, 'update transaction failed. error:' + JSON.stringify(err));
      }
    });
  }

  // 获取交易记录
  public async getTransactionsWithPagination(
    conditions: UserTablePredicateParams[],
    page: number,
    pageSize: number,
  ): Promise<TableQueryWithPaginationRsp<TransactionTableBasis>> {
    return this.queryWithPagination<TransactionTableBasis>(
      AccountingDBConstants.TRANSACTION_TABLE_NAME,
      conditions,
      page,
      pageSize,
      { field: TransactionTableFields.TRANSACTION_ID, desc: true },
    );
  }

  public async getTransactions(
    conditions: UserTablePredicateParams[],
  ): Promise<TransactionReportRsp> {
    try {
      return this.transaction<TransactionReportRsp>(async () => {
        const orderBy: TableOrderByParams = {
          field: TransactionTableFields.TRANSACTION_ID,
          desc: true,
        };
        const transactions = await this.query<TransactionTableBasis>(
          AccountingDBConstants.TRANSACTION_TABLE_NAME,
          conditions,
          orderBy,
        );

        const sqlParts: string[] = [];

        const getSqlOperator = (op: DBOperator): string => {
          switch (op) {
            case DBOperator.EQUAL: return '=';
            case DBOperator.GREATER_OR_EQUAL: return '>=';
            case DBOperator.LESS_OR_EQUAL: return '<=';
            case DBOperator.LIKE: return 'LIKE';
            default: return '=';
          }
        };

        conditions.forEach(cond => {
          const sqlOp = getSqlOperator(cond.operator);
          let val = cond.value;
          if (typeof val === 'string') {
            val = val.replace(/^'|'$/g, '');
            val = `'${val}'`;
          }
          sqlParts.push(`${cond.field} ${sqlOp} ${val}`);
        });

        const whereClause = sqlParts.length > 0 ? 'WHERE ' + sqlParts.join(' AND ') : '';

        const sql = `
        SELECT
           SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as totalIncome,
           SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) as totalExpense
        FROM transactions
           ${whereClause}
      `;

        const summary = await this.querySql<AmountSummary>(sql);
        const res: TransactionReportRsp = {
          transactions,
          totalIncome: summary[0]?.totalIncome ?? 0,
          totalExpense: summary[0]?.totalExpense ?? 0,
        };
        return res;
      });
    } catch (err) {
      Logger.error(
        TAG,
        'get transactions failed. error:' + JSON.stringify(err),
      );
      const res: TransactionReportRsp = {
        transactions: [],
        totalIncome: 0,
        totalExpense: 0,
      };
      return res;
    }
  }

  // 获取当前默认账本下的交易报表
  public async getTransactionsForDefaultAccount(
    conditions?: UserTablePredicateParams[]
  ): Promise<TransactionReportRsp> {
    const defaultAccountId = await this._getDefaultAccountId();
    if (defaultAccountId === 0) {
      Logger.warn(TAG, 'No default account found.');
      return { transactions: [], totalIncome: 0, totalExpense: 0 };
    }
    const accountCondition: UserTablePredicateParams = {
      field: TransactionTableFields.ACCOUNT_ID,
      value: defaultAccountId,
      operator: DBOperator.EQUAL,
    };
    const finalConditions = conditions
      ? [accountCondition, ...conditions]
      : [accountCondition];
    return this.getTransactions(finalConditions);
  }

  // 新增资产账户
  public async addAssetAccount(userData: UserAsset) {
    const data: AssetTableBasis = {
      assetId: new Date().getTime(),
      name: userData.name,
      type: userData.type,
      subType: userData.subType,
      category: userData.category,
      amount: userData.amount,
      note: userData.note ?? '',
    };
    return this.transaction(async () => {
      try {
        const res = await this.insert(
          AccountingDBConstants.ASSET_TABLE_NAME,
          data,
        );
        if (res === 1) {
          ToastDialog.showToast({ message: '资产账户新增成功~' });
          Logger.info(TAG, 'insert asset account success.');
        }
      } catch (err) {
        ToastDialog.showToast({ message: '资产账户新增失败，请稍后重试~' });
        Logger.error(
          TAG,
          'insert asset account failed. error:' + JSON.stringify(err),
        );
      }
    });
  }

  // 删除资产账户
  public async deleteAssetAccount(assetId: number) {
    const condition: TablePredicateParams = {
      field: AssetTableFields.ASSET_ID,
      value: assetId,
      operator: DBOperator.EQUAL,
    };
    try {
      await this.delete(AccountingDBConstants.ASSET_TABLE_NAME, [condition]);
      ToastDialog.showToast({ message: '资产账户删除成功~' });
      Logger.info(TAG, 'delete asset account success.');
    } catch (err) {
      ToastDialog.showToast({ message: '资产账户删除失败，请稍后重试~' });
      Logger.error(
        TAG,
        'delete asset account failed. error:' + JSON.stringify(err),
      );
    }
  }

  // 编辑资产账户
  public async editAssetAccount(userData: AssetTableBasis) {
    const condition: TablePredicateParams = {
      field: AssetTableFields.ASSET_ID,
      value: userData.assetId,
      operator: DBOperator.EQUAL,
    };
    const data: AssetTableBasis = {
      assetId: userData.assetId,
      name: userData.name,
      type: userData.type,
      subType: userData.subType,
      category: userData.category,
      amount: userData.amount,
      note: userData.note ?? '',
    };
    try {
      const res = await this.update<AssetTableBasis>(
        AccountingDBConstants.ASSET_TABLE_NAME,
        data,
        [condition],
      );
      if (res === 1) {
        ToastDialog.showToast({ message: '资产账户更新成功~' });
        Logger.info(TAG, 'update asset account success.');
      } else {
        throw new Error(res.toString());
      }
    } catch (err) {
      ToastDialog.showToast({ message: '资产账户更新失败，请稍后重试~' });
      Logger.error(
        TAG,
        'update asset account failed. error:' + JSON.stringify(err),
      );
    }
  }

  // 根据交易记录更新资产账户
  public async updateAssetAccountFromTransaction(
    tx: UserTransaction | TransactionTableBasis,
  ) {
    const assetId = tx.assetId;
    if (!assetId) {
      return;
    }
    const isExpense = tx.type === 'expense';
    const sql = `
    UPDATE assets
    SET amount = amount ${isExpense ? '-' : '+'} ${tx.amount}
    WHERE assetId = ${assetId}
    `;
    await this.executeSql(sql);
  }

  // 获取资产账户列表
  public async getAssetAccount(conditions: UserTablePredicateParams[]) {
    try {
      return this.transaction<AssetReport>(async () => {
        const assets = await this.query<AssetTableBasis>(
          AccountingDBConstants.ASSET_TABLE_NAME,
          conditions,
        );
        const assetIdCon = conditions[0];
        const sql = `
        SELECT
           SUM(CASE WHEN category = 1 THEN amount ELSE 0 END) as totalAsset,
           SUM(CASE WHEN category = 2 THEN amount ELSE 0 END) as totalLiability
        FROM assets
            ${assetIdCon ? 'WHERE assetId = ' + assetIdCon.value : ''}
        `;
        const summary = await this.querySql<AssetSummary>(sql);
        const res: AssetReport = {
          assets,
          totalAsset: summary[0]?.totalAsset ?? 0,
          totalLiability: summary[0]?.totalLiability ?? 0,
        };
        return res;
      });
    } catch (err) {
      Logger.error(TAG, 'get assets failed. error:' + JSON.stringify(err));
      const res: AssetReport = {
        assets: [],
        totalAsset: 0,
        totalLiability: 0,
      };
      return res;
    }
  }

  /**
   * 新增或更新预算
   */
  public async addOrUpdateBudget(accountId: number, month: string, amount: number) {
    const sql = `INSERT OR REPLACE INTO ${AccountingDBConstants.BUDGET_TABLE_NAME} (accountId, month, amount) VALUES (?, ?, ?)`;
    try {
      await this.rdbStore!.executeSql(sql, [accountId, month, amount]);
      Logger.info(TAG, `Budget updated for account ${accountId} month ${month}`);
    } catch (err) {
      Logger.error(TAG, `addOrUpdateBudget failed. error: ${JSON.stringify(err)}`);
    }
  }
  /**
   * 获取指定账本和月份的预算
   */
  public async getBudget(accountId: number, month: string): Promise<number | null> {
    const conditions: TablePredicateParams[] = [
      { field: 'accountId', value: accountId, operator: DBOperator.EQUAL },
      { field: 'month', value: month, operator: DBOperator.EQUAL }
    ];
    try {
      const result = await this.query<BudgetTableBasis>(
        AccountingDBConstants.BUDGET_TABLE_NAME,
        conditions
      );
      if (result.length > 0) {
        return result[0].amount;
      }
      return null;
    } catch (err) {
      Logger.error(TAG, `getBudget failed. error: ${JSON.stringify(err)}`);
      return null;
    }
  }
  /**
   * 清空（删除）指定账本和月份的预算
   */
  public async deleteBudget(accountId: number, month: string) {
    const conditions: TablePredicateParams[] = [
      { field: 'accountId', value: accountId, operator: DBOperator.EQUAL },
      { field: 'month', value: month, operator: DBOperator.EQUAL }
    ];
    try {
      await this.delete(AccountingDBConstants.BUDGET_TABLE_NAME, conditions);
      Logger.info(TAG, `Budget deleted for account ${accountId} month ${month}`);
    } catch (err) {
      Logger.error(TAG, `deleteBudget failed. error: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 获取指定日期之后，特定资产账户的账单影响总和
   * @param dateStr 日期字符串 (YYYY-MM-DD)
   * @param assetIds 资产ID数组
   */
  public async getTransactionImpactAfterDate(dateStr: string, assetIds: number[]): Promise<TransactionImpact[]> {
    if (!this.rdbStore || assetIds.length === 0) {
      return [];
    }
    const ids = assetIds.join(',');
    const sql = `
      SELECT assetId, SUM(CASE WHEN type='income' THEN amount ELSE -amount END) as impact
      FROM transactions
      WHERE date > '${dateStr}' AND assetId IN (${ids})
      GROUP BY assetId
    `;
    return await this.querySql<TransactionImpact>(sql);
  }

  /**
   * 获取记账统计信息：
   * - totalDays：从最早创建的账本时间到当前系统时间的天数
   * - totalBills：所有账单总笔数
   */
  public async getBillStatistics(): Promise<BillInfo> {
    try {
      const rows = await this.querySql<MinAccountId>(
        `SELECT MIN(accountId) AS minAccountId FROM ${AccountingDBConstants.ACCOUNT_TABLE_NAME}`
      );
      const minAccountId = rows[0]?.minAccountId;
      if (!minAccountId) {
        return { totalDays: 0, totalBills: 0 };
      }
      const startTime = Number(minAccountId);
      const now = Date.now();
      const diffMs = now - startTime;
      const totalDays = diffMs > 0 ? Math.floor(diffMs / (24 * 60 * 60 * 1000)) + 1 : 1;
      const totalBills = await this.count(AccountingDBConstants.TRANSACTION_TABLE_NAME, []);
      return { totalDays, totalBills };
    } catch (err) {
      Logger.error(TAG, 'getBillStatistics failed. error:' + JSON.stringify(err));
      return { totalDays: 0, totalBills: 0 };
    }
  }

  /**
   * 导出指定账本和时间范围内的交易记录
   * @param accountId 账本ID
   * @param startDate 起始日期 (yyyy-mm-dd)
   * @param endDate 结束日期 (yyyy-mm-dd)，可选，默认为当前日期
   */
  public async exportTransactions(
    accountId: number,
    startDate: string,
    endDate?: string
  ): Promise<TransactionTableBasis[]> {
    const end = endDate || new Date().toISOString().split('T')[0];

    const sql = `
      SELECT *
      FROM ${AccountingDBConstants.TRANSACTION_TABLE_NAME}
      WHERE ${TransactionTableFields.ACCOUNT_ID} = ${accountId}
        AND ${TransactionTableFields.DATE} >= '${startDate}'
        AND ${TransactionTableFields.DATE} <= '${end}'
      ORDER BY ${TransactionTableFields.DATE} DESC, ${TransactionTableFields.TRANSACTION_ID} DESC
    `;

    try {
      return await this.querySql<TransactionTableBasis>(sql);
    } catch (err) {
      Logger.error(TAG, 'export transactions failed. error:' + JSON.stringify(err));
      return [];
    }
  }
}

const accountingDB = new AccountingDB();

export { accountingDB as AccountingDB };
