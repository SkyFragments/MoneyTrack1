import { BillCardItem, DailyBillGroup, ResourceUtil } from 'bill_base';
import dayjs from 'dayjs';
import { MOCK_BILL_RESP, MOCK_DAILY_BILL_LIST } from '../mocks/MockData';
import { AccountingDB } from '../utils/accountingdb/AccountingDB';
import { TransactionTableFields } from '../utils/accountingdb/Enums';
import {
  TransactionReportRsp,
  UserTablePredicateParams,
} from '../utils/accountingdb/Types';
import { DBOperator } from '../utils/basedb/Constants';
import { AccountProcessingModel } from './AccountProcessingModel';
import { AssetProcessingModel } from './AssetProcessingModel';

@ObservedV2
export class BillProcessingModel {
  @Trace date: string = dayjs().format('YYYY-MM');
  @Trace bill: TransactionReportRsp | null = null;
  @Trace list: DailyBillGroup[] | null = null;
  @Trace assetProcessing: AssetProcessingModel = new AssetProcessingModel();
  @Trace accountProcessing: AccountProcessingModel = new AccountProcessingModel();
  @Trace billStartDate: string = '';
  @Trace billEndDate: string = '';

  @Computed
  public get currentAccountId(): number {
    return this.accountProcessing.getCurrentAccountId();
  }

  @Computed
  public get dateLabel() {
    if (this.date) {
      return dayjs(new Date(this.date)).format('YYYY年MM月');
    }
    return dayjs().format('YYYY年MM月');
  }

  @Computed
  public get totalIncome() {
    return this.bill?.totalIncome?.toFixed(2) ?? '0.00';
  }

  @Computed
  public get totalExpense() {
    return this.bill?.totalExpense?.toFixed(2) ?? '0.00';
  }

  public previewMock() {
    this.bill = MOCK_BILL_RESP;
    this.list = MOCK_DAILY_BILL_LIST;
  }

  public changeMonth(date: string) {
    this.date = date;
  }

  public async getBillReport(checkedResource: number = -1, date: string = '') {
    if (date) {
      this.changeMonth(date);
    }

    const currentAccount = this.accountProcessing.currentAccount;
    // 获取当前账本的结算日，默认为01
    const settlementDayStr = currentAccount?.date || '01';
    const settlementDay = parseInt(settlementDayStr);

    // 计算查询的起止日期
    const selectedMonth = dayjs(this.date);
    const startDate = selectedMonth.date(settlementDay).format('YYYY-MM-DD');
    const nextMonth = selectedMonth.add(1, 'month');
    const endDate = nextMonth.date(settlementDay).subtract(1, 'day').format('YYYY-MM-DD');
    this.billStartDate = startDate;
    this.billEndDate = endDate;

    const currentId = this.accountProcessing.getCurrentAccountId();

    let conditions: UserTablePredicateParams[] = [];

    // 账本ID条件
    const accountCondition: UserTablePredicateParams = {
      field: TransactionTableFields.ACCOUNT_ID,
      value: currentId,
      operator: DBOperator.EQUAL,
    };
    conditions.push(accountCondition);

    // 日期范围条件
    conditions.push({
      field: TransactionTableFields.DATE,
      value: startDate,
      operator: DBOperator.GREATER_OR_EQUAL,
    });

    conditions.push({
      field: TransactionTableFields.DATE,
      value: endDate,
      operator: DBOperator.LESS_OR_EQUAL,
    });

    if (checkedResource !== -1) {
      const resourceCondition: UserTablePredicateParams = {
        field: TransactionTableFields.RESOURCE,
        value: checkedResource,
        operator: DBOperator.EQUAL,
      };
      conditions.push(resourceCondition);
    }

    this.bill = await AccountingDB.getTransactions(conditions);
    await this._setBillGroup(this.bill);
  }

  public async getBillReportByAsset(assetId: number) {
    const condition: UserTablePredicateParams = {
      field: TransactionTableFields.ASSET_ID,
      value: assetId,
      operator: DBOperator.EQUAL,
    };
    this.bill = await AccountingDB.getTransactions([condition]);
    this._setBillGroup(this.bill);
  }

  private async _setBillGroup(res: TransactionReportRsp) {
    const map: Map<string, BillCardItem[]> = new Map();

    const promises = res.transactions.map(async (item) => {
      const resourceItem = ResourceUtil.getResourceItem(item.resource);
      const card: BillCardItem = {
        accountId: item.accountId,
        date: item.date,
        transactionId: item.transactionId,
        resource: item.resource,
        icon: resourceItem.icon,
        title: resourceItem.name,
        note: item.note,
        amount: item.amount,
        type: item.type,
      };
      if (item.assetId) {
        const condition: UserTablePredicateParams = {
          field: TransactionTableFields.ASSET_ID,
          value: item.assetId,
          operator: DBOperator.EQUAL,
        };
        const assetRes = await AccountingDB.getAssetAccount([condition]);
        if (assetRes.assets.length === 1) {
          const assetName = assetRes.assets[0].name;
          card.assetName = assetName;
        }
      }
      if (map.has(item.date)) {
        map.get(item.date)?.push(card);
      } else {
        map.set(item.date, [card]);
      }
    });

    await Promise.all(promises);

    this.list = Array.from(map).map((item) => {
      const date = item[0];
      const list = item[1];
      list.sort((a, b) => b.transactionId - a.transactionId);
      const group: DailyBillGroup = {
        dateStr: dayjs(new Date(date)).format('YYYY-MM-DD'),
        list,
      };
      return group;
    });
    this.list.sort(
      (a, b) => new Date(b.dateStr).getTime() - new Date(a.dateStr).getTime(),
    );
  }
}
