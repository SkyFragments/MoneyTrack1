import { SettingGroup, SettingItem, SettingType } from 'app_setting';
import { AccountingDB, BillInfo, AccountTableBasis, TransactionTableBasis, AssetTableBasis } from 'bill_data_processing';
import { iData, RouterMap, RouterModule } from 'commonlib';
import { ServiceMenuItem } from '../common/Types';
import { SyncApis } from 'lib_network';
import { ToastDialog } from '@hw-agconnect/ui-toast';
import { BalanceChangeType } from 'bill_base';
import { LoginUtil } from '../viewmodels/LoginVM';

interface SyncPullData {
  accounts: AccountTableBasis[];
  transactions: TransactionTableBasis[];
  assets: AssetTableBasis[];
  budgets: object[];
}

@ObservedV2
export class MineVM {
  @Trace list: SettingItem[] = [
    new SettingItem()
      .setType(SettingType.ROUTER)
      .setLabel('意见反馈')
      .setIcon($r('app.media.ic_mine_feedback'))
      .setClickEvent(() => { RouterModule.push({ url: RouterMap.FEEDBACK })}),
    new SettingItem()
      .setType(SettingType.TEXT)
      .setLabel('云同步')
      .setIcon($r('app.media.ic_mine_export'))
      .setClickEvent(() => { this.doSync() }),
  ];
  @Trace group: SettingGroup = new SettingGroup().setList(this.list)
  @Trace totalDays: number = 0;
  @Trace totalBills: number = 0;

  gridClick(v: ServiceMenuItem) {
    RouterModule.push({ url: v.routerName });
  }

  async loadBillInfo() {
    try {
      const billInfo: BillInfo = await AccountingDB.getBillStatistics();
      this.totalDays = billInfo.totalDays;
      this.totalBills = billInfo.totalBills;
    } catch (err) {
      console.error('loadBillInfo failed', err);
      this.totalDays = 0;
      this.totalBills = 0;
    }
  }

  async doSync() {
    if (LoginUtil.checkGuestMode()) {
      ToastDialog.showToast({ message: '请先登录后再进行云同步' });
      return;
    }
    if (!iData.global.isLogin) {
      ToastDialog.showToast({ message: '请先登录后再进行云同步' });
      return;
    }
    try {
      ToastDialog.showToast({ message: '正在同步...' });
      const res = await SyncApis.pull();
      if (res.code === 0 && res.data) {
        const data: SyncPullData = res.data as SyncPullData;
        const existingAccounts = data.accounts?.length ? await AccountingDB.getAccounts() : [];
        const existingAccountIds = new Set(existingAccounts.map((a: AccountTableBasis) => a.accountId));
        for (const account of (data.accounts || [])) {
          if (!existingAccountIds.has(account.accountId)) {
            await AccountingDB.addAccount(account);
          }
        }
        for (const tx of (data.transactions || [])) {
          await AccountingDB.addTransaction({
            accountId: tx.accountId,
            type: tx.type as BalanceChangeType,
            resource: tx.resource,
            amount: tx.amount,
            date: tx.date,
            note: tx.note,
            excluded: tx.excluded,
            assetId: tx.assetId,
          });
        }
        for (const asset of (data.assets || [])) {
          await AccountingDB.addAssetAccount(asset);
        }
        ToastDialog.showToast({ message: '同步成功' });
      } else {
        ToastDialog.showToast({ message: res.msg || '同步失败' });
      }
    } catch (err) {
      ToastDialog.showToast({ message: '同步失败' });
    }
  }
}
