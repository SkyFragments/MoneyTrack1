import { BalanceChangeType } from './Enums';

export interface BillCardItem {
  accountId: number;
  date: string;
  transactionId: number;
  resource: number;
  icon: ResourceStr;
  title: string;
  note?: string;
  amount: number;
  type: BalanceChangeType;
  assetId?: number;
  assetName?: string;
}

export interface DailyBillGroup {
  dateStr: string;
  list: BillCardItem[];
}

export interface BalanceResourceItem {
  key: number;
  name: string;
  icon: ResourceStr;
  uncheckedIcon: ResourceStr;
  type: BalanceChangeType;
  sortNum: number;
  isCustom?: number;
}
