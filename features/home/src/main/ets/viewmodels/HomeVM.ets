import { ToastDialog } from '@hw-agconnect/ui-toast';
import { emitter } from '@kit.BasicServicesKit';
import {
  BalanceChangeType,
  BalanceResourceModel,
  ResourceUtil,
} from 'bill_base';
import { AccountingDB, BillProcessingModel } from 'bill_data_processing';
import {
  ConfirmParam,
  DialogInfo,
  DialogMap,
  EventBus,
  EventKey,
  RouterModule,
  WindowUtil
} from 'commonlib';
import { HomeConstants } from '../commons/Constants';
import { HomeSheetType } from '../commons/Enums';
import { HomeSheetModel } from '../commons/Models';

@ObservedV2
export class HomeVM {
  @Trace checkedType: BalanceChangeType = BalanceChangeType.INCOME;
  @Trace checkedResource: number = HomeConstants.RESOURCE_NO_FILTER;
  @Trace resource: BalanceResourceModel = ResourceUtil.getResourceList();
  @Trace showSheet: boolean = true;
  @Trace sheet: HomeSheetModel = new HomeSheetModel();
  @Trace dataProcessing: BillProcessingModel = new BillProcessingModel();

  @Computed
  public get currentResourceItem() {
    if (this.checkedResource === HomeConstants.RESOURCE_NO_FILTER) {
      return null;
    }
    let list =
      this.checkedType === BalanceChangeType.INCOME
        ? this.resource.income
        : this.resource.expense;
    const item = Array.from(list).find(
      (item) => item.key === this.checkedResource,
    );
    return item;
  }

  @Computed
  public get resourceLabel() {
    return this.currentResourceItem?.name ?? '全部类型';
  }

  public async initData() {
    await this.dataProcessing.accountProcessing.init();
    await this.refreshBill();
    EventBus.instance.on(EventKey.GLOBAL_REFRESH_EVENT, () => {
      this.refreshBill();
    });
  }

  public openSheet(type: HomeSheetType) {
    this.sheet.type = type;
    if (type === HomeSheetType.DATE) {
      this.sheet.sheetHeight = 360;
      this.sheet.title = '选择月份';
    } else if (type === HomeSheetType.TYPE) {
      this.sheet.sheetHeight = 540;
      this.sheet.title = '选择类型';
    }
  }

  public async refreshBill() {
    await this.dataProcessing.accountProcessing.loadAccounts();
    this.dataProcessing.getBillReport(this.checkedResource);
    try {
      emitter.emit({ eventId: 1 });
    } catch (error) {
      WindowUtil.dealAllError(error);
    }
  }

  public async deleteBill(id: number) {
    RouterModule.push({
      url: DialogMap.COMMON_CONFIRM,
      param: {
        message: '删除后账单无法恢复，是否确认删除？',
      },
      onPop: async (value) => {
        const result = value.result as DialogInfo<ConfirmParam>;
        if (result.param?.isConfirm) {
          await AccountingDB.deleteTransactions(id);
          ToastDialog.showToast({ message: '账单删除成功~' });
          EventBus.instance.emit(EventKey.GLOBAL_REFRESH_EVENT);
        }
      },
    });
  }

  public async changeMonth(dateStr: string) {
    this.dataProcessing.changeMonth(dateStr);
    await this.refreshBill();
  }

  public async changeResource(type: BalanceChangeType, key: number) {
    this.checkedType = type;
    this.checkedResource = key;
    await this.refreshBill();
  }
}
