import {
  BalanceChangeType,
  BalanceResourceItem,
  ResourceUtil,
} from 'bill_base';
import { BillProcessingModel } from 'bill_data_processing';
import { RouterMap, RouterModule } from 'commonlib';
import dayjs from 'dayjs';
import { BillByResourceRouteParams } from '../commons/Types';

@ObservedV2
export class BillByResourceVM {
  @Trace
  dataProcessing: BillProcessingModel = new BillProcessingModel();
  @Trace
  resourceItem: BalanceResourceItem | undefined = undefined;

  @Computed
  public get summaryLabel() {
    if (!this.resourceItem) {
      return '';
    }
    const dateStr = dayjs(this.dataProcessing.date).format('M月');
    const typeStr =
      this.resourceItem.type === BalanceChangeType.EXPENSE ? '支出' : '收入';
    return dateStr + this.resourceItem.name + '共' + typeStr;
  }

  @Computed
  public get summaryAmount() {
    if (this.resourceItem?.type === BalanceChangeType.EXPENSE) {
      return this.dataProcessing.bill?.totalExpense?.toFixed(2) ?? '0.00';
    } else if (this.resourceItem?.type === BalanceChangeType.INCOME) {
      return this.dataProcessing.bill?.totalIncome?.toFixed(2) ?? '0.00';
    }
    return '0.00';
  }

  public async initData() {
    await this.dataProcessing.accountProcessing.init();
    const params = RouterModule.getNavParam<BillByResourceRouteParams>({
      url: RouterMap.STATISTICS_BILL_BY_RESOURCE,
    });
    if (params) {
      this.dataProcessing.getBillReport(params.resource, params.date);
      this.resourceItem = ResourceUtil.getResourceItem(params.resource);
    }
  }
}
