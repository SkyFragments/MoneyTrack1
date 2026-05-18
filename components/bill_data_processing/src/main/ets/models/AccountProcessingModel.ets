import { AccountType } from 'bill_base';
import { AccountingDB } from '../utils/accountingdb/AccountingDB';
import { AccountTableBasis } from '../utils/accountingdb/Types';

@ObservedV2
export class AccountProcessingModel {
  // 账本列表
  @Trace accounts: AccountTableBasis[] = [];

  // 当前选中的账本
  @Trace currentAccount: AccountTableBasis | null = null;

  /**
   * 初始化：加载账本列表并设置默认账本
   */
  public async init() {
    await this.loadAccounts();
  }

  /**
   * 从数据库加载账本列表
   */
  public async loadAccounts() {
    try {
      this.accounts = await AccountingDB.getAccounts();
      const defaultAccount = this.accounts.find(acc => acc.type === AccountType.DEFAULT);

      if (defaultAccount) {
        this.currentAccount = defaultAccount;
      } else if (this.accounts.length > 0) {
        this.currentAccount = this.accounts[0];
      } else {
        this.currentAccount = null;
      }
    } catch (err) {
      console.error('Failed to load accounts', err);
    }
  }

  /**
   * 切换当前账本
   */
  public switchAccount(accountId: number) {
    const target = this.accounts.find(acc => acc.accountId === accountId);
    if (target) {
      this.currentAccount = target;
    }
  }

  /**
   * 获取当前账本ID
   */
  public getCurrentAccountId(): number {
    return this.currentAccount?.accountId ?? 0;
  }
}
