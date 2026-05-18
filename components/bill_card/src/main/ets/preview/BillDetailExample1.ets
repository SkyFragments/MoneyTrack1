import { BalanceChangeType, BillCardItem, Logger } from 'bill_base';
import { BillDetail } from '../components/BillDetail';

const TAG = '[BillDetailExample1]'

const MOCK_BILL_ITEM: BillCardItem =
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
  };

@Entry
@ComponentV2
struct BillDetailExample1 {
  @Local bill: BillCardItem = MOCK_BILL_ITEM;

  build() {
    Column() {
      // 账单卡片
      BillDetail({
        bill: this.bill,
        amountFontColor: Color.Pink,
        handleEdit: () => {
          try {
            this.getUIContext().getPromptAction().showToast({
              message: '触发了账单的编辑事件，随机生成一个金额',
              alignment: Alignment.Top
            });
          } catch (err) {
            Logger.error(TAG, 'show toast failed. error:' + JSON.stringify(err));
          }
          const newBill = JSON.parse(JSON.stringify(MOCK_BILL_ITEM)) as BillCardItem;
          newBill.amount = new Date().getSeconds();
          this.bill = newBill;
        },
        handleDelete: () => {
          try {
            this.getUIContext().getPromptAction().showToast({
              message: '触发了账单的删除事件',
              alignment: Alignment.Top
            });
          } catch (err) {
            Logger.error(TAG, 'show toast failed. error:' + JSON.stringify(err));
          }
        },
      });
    }
    .padding(16)
    .backgroundColor('#eee');
  }
}