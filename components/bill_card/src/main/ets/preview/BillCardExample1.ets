import { BalanceChangeType, BillCardItem } from 'bill_base';
import { BillCard } from '../components/BillCard';

const MOCK_BILL_LIST: BillCardItem[] = [
  {
    accountId: 1,
    date: '2025-05-15',
    transactionId: 1,
    resource: 100,
    icon: $r('app.media.ic_expense_0'),
    title: '餐饮',
    note: '黄焖鸡',
    amount: 30,
    type: BalanceChangeType.EXPENSE,
    assetName: '支付宝',
  },
];

@Entry
@ComponentV2
struct BillCardExample1 {
  build() {
    Column() {
      // 账单卡片
      BillCard({
        card: {
          dateStr: '2025-05-30',
          list: MOCK_BILL_LIST,
        },
      });

      BillCard({
        emptyNoteSize: 20,
        emptyNoteColor: Color.Pink,
      });
    }
    .padding(16)
    .backgroundColor('#eee');
  }
}