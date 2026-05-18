import { BillCardItem } from 'bill_base';
import {
  billManageSheetBuilder,
  BillManageSheetOptions
} from 'bill_manage';
import { RouterMap, RouterModule } from 'commonlib';
import { AccountingDB } from './accountingdb/AccountingDB';
import { UserTransaction, TransactionTableBasis } from './accountingdb/Types';
import { PopViewUtil } from './PopViewUtil';

class BillManageUtil {
  public manageBill(
    initBill: BillCardItem | undefined = undefined,
    assetId: number | undefined = undefined,
    accountId: number,
    callback?: (data: UserTransaction) => void,
  ) {
    PopViewUtil.openSheet(
      wrapBuilder(billManageSheetBuilder),
      {
        detents: [SheetSize.LARGE],
        title: { title: '记一笔' },
        preferType:SheetType.BOTTOM,
      },
      {
        initBill,
        handleConfirm: (data: UserTransaction) => {
          data.accountId = accountId;
          if (!initBill) {
            this._addBill(data, assetId, callback);
          } else {
            this._editBill(data, callback);
          }
        },
        handleResourceManage: () => {
          PopViewUtil.closeSheet();
          RouterModule.push({ url: RouterMap.HOME_RESOURCE_MANAGE });
        },
      } as BillManageSheetOptions,
    );
  }

  private async _addBill(
    data: UserTransaction,
    assetId: number | undefined = undefined,
    callback?: (data: UserTransaction) => void,
  ) {
    if (typeof assetId === 'number') {
      data.assetId = assetId;
    }
    await AccountingDB.addTransaction(data);
    PopViewUtil.closeSheet();
    callback?.(data);
  }

  private async _editBill(
    data: UserTransaction,
    callback?: (data: UserTransaction) => void,
  ) {
    await AccountingDB.updateTransactions(data as TransactionTableBasis);
    PopViewUtil.closeSheet();
    callback?.(data);
  }
}

const util = new BillManageUtil();

export { util as BillManageUtil };
