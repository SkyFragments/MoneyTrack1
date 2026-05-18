import { BalanceChangeType, BillCardItem } from 'bill_base';
import { BillCard } from '../components/BillCard';
import { BillItem } from '../components/BillCardItem';
import { BillDetail } from '../components/BillDetail';
import { BillSummaryCard } from '../components/BillSummaryCard';

const MOCK_BILL_ITEM: BillCardItem = {
  accountId: 1,
  date: '2025-05-15',
  transactionId: 1,
  resource: 100,
  icon: $r('app.media.ic_expense_0'),
  title: '餐饮',
  note: '黄焖鸡',
  amount: 30,
  type: BalanceChangeType.EXPENSE,
  assetName:'支付宝',
};

@Entry
@ComponentV2
struct PreviewPage {
  build() {
    Scroll() {
      Column({ space: 16 }) {
        // 账单卡片
        BillCard({
          card:{
            dateStr:'2025-05-30',
            list:[MOCK_BILL_ITEM],
          },
        });
        // 账单卡片条目
        BillItem({
          billItem: MOCK_BILL_ITEM,
        });
        // 账单汇总卡片
        BillSummaryCard();
        // 单条账单详情卡片
        BillDetail({
          bill: MOCK_BILL_ITEM,
        });
      }
      .padding(16)
      .backgroundColor('#eee');
    };
  }
}