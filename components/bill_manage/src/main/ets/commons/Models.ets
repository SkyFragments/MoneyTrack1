import { BalanceChangeType } from 'bill_base';

@ObservedV2
export class BillManageModel {
  @Trace accountId: number = 0;
  @Trace type: BalanceChangeType = BalanceChangeType.EXPENSE;
  @Trace transactionId?: number | undefined = undefined;
  @Trace resource: number = 101;
  @Trace amount: number = 0;
  @Trace date: string = ''; // yyyy-mm-dd
  @Trace note?: string;
  @Trace assetId?: number;
}
