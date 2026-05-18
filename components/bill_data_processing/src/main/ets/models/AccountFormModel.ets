import { AccountType } from 'bill_base';
import { AccountTableBasis } from '../utils/accountingdb/Types';

@ObservedV2
export class AccountFormModel {
  @Trace accountId: number = 0;
  @Trace name: string = '';
  @Trace type: AccountType = AccountType.CUSTOM;
  @Trace date: string = '01';
  @Trace accountIncome: number = 0;
  @Trace accountExpense: number = 0;

  // 从接口数据初始化 Model
  public init(data: AccountTableBasis) {
    this.accountId = data.accountId;
    this.name = data.name;
    this.type = data.type;
    this.date = data.date;
    this.accountIncome = data.accountIncome;
    this.accountExpense = data.accountExpense;
  }

  public toAccountTableBasis(): AccountTableBasis {
    return {
      accountId: this.accountId,
      name: this.name,
      type: this.type,
      date: this.date,
      accountIncome: this.accountIncome,
      accountExpense: this.accountExpense
    };
  }
}
