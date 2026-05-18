import { BalanceChangeType, DailyBillGroup } from 'bill_base';
import { TransactionReportRsp } from '../utils/accountingdb/Types';

export const MOCK_BILL_RESP: TransactionReportRsp = {
  transactions: [
    {
      accountId: 1,
      amount: 20,
      date: '2025-05-13',
      note: '',
      resource: 101,
      transactionId: 1747140598246,
      type: BalanceChangeType.EXPENSE,
    },
    {
      accountId: 1,
      amount: 30,
      date: '2025-05-14',
      note: '',
      resource: 101,
      transactionId: 1747193424022,
      type: BalanceChangeType.EXPENSE,
    },
  ],
  totalIncome: 0,
  totalExpense: 50,
};

export const MOCK_DAILY_BILL_LIST: DailyBillGroup[] = [
  {
    dateStr: '2025-05-14',
    list: [
      {
        accountId: 1,
        date: '2025-05-14',
        transactionId: 1747193424022,
        resource: 101,
        icon: $r('app.media.ic_expense_0'),
        title: '餐饮',
        note: '',
        amount: 30,
        type: BalanceChangeType.EXPENSE,
      },
    ],
  },
  {
    dateStr: '2025-05-13',
    list: [
      {
        accountId: 1,
        date: '2025-05-13',
        transactionId: 1747140598246,
        resource: 101,
        icon: $r('app.media.ic_expense_0'),
        title: '餐饮',
        note: '',
        amount: 20,
        type: BalanceChangeType.EXPENSE,
      },
    ],
  },
];
