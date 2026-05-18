import { UIDialog } from '@hw-agconnect/ui-dialog';
import { ToastDialog } from '@hw-agconnect/ui-toast';
import {
  BalanceChangeType,
  BillCardItem,
  BillCardItemModel,
  ResourceUtil,
} from 'bill_base';
import {
  AccountingDB,
  BillManageUtil,
  UserTransaction,
} from 'bill_data_processing';
import {
  EventBus,
  EventKey,
  Logger,
  RouterMap,
  RouterModule
} from 'commonlib';

const TAG = '[BillDetailVM]';

@ObservedV2
export class BillDetailVM {
  @Trace bill: BillCardItemModel = new BillCardItemModel();

  @Computed
  public get isIncome() {
    return Boolean(this.bill?.type === BalanceChangeType.INCOME);
  }

  public initData() {
    const data = RouterModule.getNavParam<BillCardItem>({
      url: RouterMap.HOME_BILL_DETAIL,
    });
    if (data) {
      this.bill.accountId = data.accountId;
      this.bill.transactionId = data.transactionId;
      this.bill.resource = data.resource;
      this.bill.icon = data.icon;
      this.bill.title = data.title;
      this.bill.note = data.note;
      this.bill.amount = data.amount;
      this.bill.type = data.type;
      this.bill.date = data.date;
    }
  }

  public deleteBill() {
    UIDialog.open({
      contentOptions: {
        content: '删除后将无法恢复，是否确认删除？',
        contentFontWeight: FontWeight.Regular,
      },
      confirmButtonOptions: {
        button: '删除',
        buttonFontColor: $r('app.color.warning_color'),
      },
      cancelButtonOptions: {
        buttonFontColor: $r('app.color.font_color_level1'),
      },
      showConfirmButton: true,
      showCancelButton: true,
      onConfirm: async () => {
        await AccountingDB.deleteTransactions(this.bill.transactionId);
        ToastDialog.showToast({ message: '账单删除成功~' });
        EventBus.instance.emit(EventKey.GLOBAL_REFRESH_EVENT);
        UIDialog.closeLast();
        RouterModule.pop(1);
      }
    })
  }

  public editBill() {
    BillManageUtil.manageBill(this.bill, undefined, this.bill.accountId, (data: UserTransaction) => {
      try {
        const resourceItem = ResourceUtil.getResourceItem(data.resource);
        this.bill.accountId = this.bill.accountId;
        this.bill.transactionId = this.bill.transactionId;
        this.bill.date = data.date;
        this.bill.resource = resourceItem.key;
        this.bill.title = resourceItem.name;
        this.bill.icon = resourceItem.icon;
        this.bill.amount = data.amount;
        this.bill.type = data.type;
        this.bill.note = data.note;
        EventBus.instance.emit(EventKey.GLOBAL_REFRESH_EVENT);
      } catch (error) {
        Logger.error(TAG, 'edit bill failed.error:' + JSON.stringify(error));
      }
    });
  }
}
