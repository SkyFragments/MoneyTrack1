import { Type } from '@kit.ArkUI';
import { BalanceChangeType } from './Enums';
import { BillCardItem, DailyBillGroup } from './Types';

@ObservedV2
export class DailyBillGroupModel implements DailyBillGroup {
  @Trace dateStr: string = '';
  @Trace list: BillCardItem[] = [];
}

@ObservedV2
export class BalanceResourceItemModel {
  @Trace key: number = 0;
  @Trace name: string = '';
  @Trace type: BalanceChangeType = BalanceChangeType.EXPENSE;
  @Trace sortNum: number = 0;
  @Trace isCustom?: number = 0;
}

@ObservedV2
export class BalanceResourceModel {
  @Type(BalanceResourceItemModel)
  @Trace
  income: BalanceResourceItemModel[] = [];
  @Type(BalanceResourceItemModel)
  @Trace
  expense: BalanceResourceItemModel[] = [];
}

@ObservedV2
export class BillCardItemModel implements BillCardItem {
  @Trace accountId: number = 0;
  @Trace date: string = '';
  @Trace transactionId: number = -1;
  @Trace resource: number = 0;
  @Trace icon: ResourceStr = '';
  @Trace title: string = '';
  @Trace note?: string;
  @Trace amount: number = 0;
  @Trace type: BalanceChangeType = BalanceChangeType.EXPENSE;
}
