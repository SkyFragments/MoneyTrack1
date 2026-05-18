import { AssetSummary } from 'asset_base';
import { BalanceChangeType, AccountType } from 'bill_base';
import { TablePredicateParams } from '../basedb/Types';
import {
  AccountTableFields,
  TransactionTableFields,
  AssetTableFields,
} from './Enums';

export interface UserTransaction {
  accountId: number;
  transactionId?: number;
  type: BalanceChangeType;
  resource: number;
  amount: number;
  date: string; // yyyy-mm-dd
  note?: string;
  excluded?: boolean;
  assetId?: number;
}

export interface UserTablePredicateParams extends TablePredicateParams {
  field: AccountTableFields | TransactionTableFields | AssetTableFields;
}

export interface AccountingResource {
  name: string;
  key: number;
}

export interface AccountTableBasis {
  accountId: number;
  name: string;
  type: AccountType;
  date: string;
  accountIncome: number;
  accountExpense: number;
  transactionCount?: number;
}

export interface TransactionTableBasis extends UserTransaction {
  transactionId: number;
}

export interface AmountSummary {
  totalIncome: number;
  totalExpense: number;
}

export interface TransactionReportRsp extends AmountSummary {
  transactions: TransactionTableBasis[];
}

export interface UserAsset {
  name: string;
  type: number;
  subType: number;
  category: number;
  amount: number;
  note?: string;
  isCustom?: boolean;
}

export interface AssetTableBasis extends UserAsset {
  assetId: number;
  note: string;
}

export interface BudgetTableBasis {
  id: number;
  accountId: number;
  month: string;
  amount: number;
}

export interface AssetReport extends AssetSummary {
  assets: AssetTableBasis[];
}

export interface BillInfo {
  totalDays: number;
  totalBills: number;
}

export interface MinAccountId {
  minAccountId: number;
}
