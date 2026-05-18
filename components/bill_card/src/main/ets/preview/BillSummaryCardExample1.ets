import { BalanceChangeType, BillCardItem, DailyBillGroupModel } from 'bill_base';
import { BillCard } from '../components/BillCard';
import { BillSummaryCard } from '../components/BillSummaryCard';

@Entry
@ComponentV2
struct BillSummaryCardExample1 {
  @Local model: DailyBillGroupModel = new DailyBillGroupModel();

  @Computed
  get totalExpense() {
    return this.model.list.reduce((pre, cur) => pre + cur.amount, 0).toFixed(2);
  }

  aboutToAppear(): void {
    this.model.dateStr = '2025-05-30';
  }

  build() {
    Column({ space: 16 }) {
      Button('添加账单')
        .onClick(() => {
          const newItem: BillCardItem = {
            accountId: 1,
            date: '2025-05-30',
            transactionId: new Date().getTime(),
            resource: 100,
            icon: $r('app.media.ic_expense_0'),
            title: '餐饮',
            note: '黄焖鸡',
            amount: 30,
            type: BalanceChangeType.EXPENSE,
          };
          this.model.list.push(newItem);
        });

      BillSummaryCard({
        totalExpense: this.totalExpense,
      });

      BillCard({
        card: this.model,
        handleDelete: (id) => {
          const idx = this.model.list.findIndex((item) => item.transactionId === id);
          if (idx) {
            this.model.list.splice(idx, 1);
          }
        },
      });
    }
    .padding(16)
    .backgroundColor('#eee');
  }
}