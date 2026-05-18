import { Logger, ResourceUtil } from 'bill_base';
import { BillManageModel } from '../commons/Models';
import { billManageSheetBuilder } from '../components/BillManageSheet';
import { resourceManageSheetBuilder } from '../components/ResourceManageSheet';

const TAG = '[ResourceManageSheetExample1]'

@Entry
@ComponentV2
struct ResourceManageSheetExample1 {
  @Local showSheet: boolean = false;
  @Local showResourceSheet: boolean = false;
  @Local bill: BillManageModel | undefined = undefined;

  @Computed
  get resourceName() {
    if (!this.bill) {
      return '';
    }
    const item = ResourceUtil.getResourceItem(this.bill.resource);
    return item.name ?? '';
  }

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
          Text('来源： ' + this.resourceName);
          Text('金额： ' + this.bill.amount);
        }
        .alignItems(HorizontalAlign.Start);
      }
      Column()
        .bindSheet($$this.showResourceSheet,
          resourceManageSheetBuilder({
            handleDeleteSuccess: async(key) => {
              if (this.bill?.resource === key) {
                this.bill = undefined;
              }
            },
          }),
          {
            title: { title: '分类管理' },
            detents: [SheetSize.FIT_CONTENT],
            backgroundColor: '#fff',
          },
        );
    }
    .bindSheet($$this.showSheet,
      billManageSheetBuilder({
        initBill: this.bill,
        handleConfirm: (data) => {
          this.bill = data;
          this.showSheet = false;
        },
        handleResourceManage: () => {
          this.showResourceSheet = true;
        },
      }), {
        title: { title: '选择资产类型' },
        detents: [SheetSize.FIT_CONTENT],
      });
  }
}

