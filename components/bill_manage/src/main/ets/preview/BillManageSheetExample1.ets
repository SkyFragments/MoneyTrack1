import { Logger } from 'bill_base';
import { BillManageModel } from '../commons/Models';
import { billManageSheetBuilder } from '../components/BillManageSheet';

const TAG = '[BillManageSheetExample1]'

@Entry
@ComponentV2
struct BillManageSheetExample1 {
  @Local showSheet: boolean = false;
  @Local bill: BillManageModel | undefined = undefined;

  build() {
    Column({ space: 24 }) {
      Row() {
        Button(this.bill ? '编辑账单' : '创建账单')
          .onClick(() => {
            this.showSheet = !this.showSheet;
          });
        if (this.bill) {
          Button('删除账单')
            .onClick(() => {
              this.bill = undefined;
              try {
                this.getUIContext().getPromptAction().showToast({ message: '删除账单成功！' });
              } catch (err) {
                Logger.error(TAG, 'show toast failed. error:' + JSON.stringify(err));
              }
            });
        }
      };

      if (this.bill) {
        Column() {
          Text('账单');
          Text('日期： ' + this.bill.date);
          Text('来源： ' + this.bill.resource);
          Text('金额： ' + this.bill.amount);
        }
        .alignItems(HorizontalAlign.Start);
      }

    }
    .bindSheet($$this.showSheet,
      billManageSheetBuilder({
        initBill: this.bill,
        handleConfirm: (data) => {
          this.bill = data;
          this.showSheet = false;
        },
        handleResourceManage: () => {
          try {
            this.getUIContext().getPromptAction().showToast({ message: '详见ResourceManageSheet组件' });
          } catch (err) {
            Logger.error(TAG, 'show toast failed. error:' + JSON.stringify(err));
          }
        },
      }), {
        title: { title: '选择资产类型' },
        detents: [SheetSize.FIT_CONTENT],
        preferType:SheetType.BOTTOM,
      });
  }
}

