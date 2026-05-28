import { SettingGroup, SettingItem, SettingType } from 'app_setting';
import { AccountingDB, BillInfo, AccountTableBasis, TransactionTableBasis, AssetTableBasis, AssetReport } from 'bill_data_processing';
import { iData, RouterMap, RouterModule } from 'commonlib';
import { ServiceMenuItem } from '../common/Types';
import { SyncApis } from 'lib_network';
import { ToastDialog } from '@hw-agconnect/ui-toast';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BalanceChangeType } from 'bill_base';
import { LoginUtil } from '../viewmodels/LoginVM';
import { AuthCache } from 'commonlib';

interface SyncPullParams {
  since?: string;
}

interface SyncPullData {
  accounts: object[];
  transactions: object[];
  assets: object[];
  budgets: object[];
  serverTime?: number | string;
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
    new SettingItem()
      .setType(SettingType.ROUTER)
      .setLabel('退出登录')
      .setIcon($r('app.media.ic_mine_export'))
      .setClickEvent(() => { this.doLogout() }),
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
      // Push local data to cloud first
      let pushSuccess = true;
      try {
        const localAccounts = await AccountingDB.getAccounts();
        const localTxResult = await AccountingDB.getTransactionsForDefaultAccount();
        const localAssetsResult = await AccountingDB.getAssetAccount([]);
        const localBudgets = await AccountingDB.getBudgetsForSync();
        const pushRes = await SyncApis.push({
          accounts: localAccounts,
          transactions: localTxResult.transactions,
          assets: localAssetsResult.assets,
          budgets: localBudgets,
        });
        pushSuccess = pushRes.code === 0 && (pushRes.data?.counts?.accounts ?? -1) >= 0;
        // Apply localId → serverId mappings from push
        if (pushRes.data?.mappings?.length) {
          for (const mapping of pushRes.data.mappings) {
            if (mapping.table === 'transactions' && mapping.localId != null) {
              await AccountingDB.updateTransactionServerId(Number(mapping.localId), mapping.serverId);
            }
          }
        }
      } catch (_e) {
        console.error('[MineVM] doSync push failed', _e);
        pushSuccess = false;
      }
      // Pull cloud data with incremental sync
      const since = AuthCache.getLastSyncTime();
      const res = await SyncApis.pull(since > 0 ? { since: since.toString() } as SyncPullParams : undefined);
      if (res.code === 0 && res.data) {
        const data: SyncPullData = res.data as SyncPullData;
        const accountList: AccountTableBasis[] = (data.accounts || []) as AccountTableBasis[];
        for (const account of accountList) {
          if (account.accountId != null && account.accountId !== 0) {
            await AccountingDB.addAccount(account);
          }
        }
        const txList: TransactionTableBasis[] = (data.transactions || []) as TransactionTableBasis[];
        for (const tx of txList) {
          if (tx.accountId == null || tx.accountId === 0) {
            continue;
          }
          if (!tx.type) {
            continue;
          }
          const txType = String(tx.type);
          if (txType !== BalanceChangeType.EXPENSE && txType !== BalanceChangeType.INCOME) {
            continue;
          }
          await AccountingDB.addTransaction({
            transactionId: tx.transactionId as number,
            accountId: tx.accountId as number,
            type: txType as BalanceChangeType,
            resource: Number(tx.resource) || 0,
            amount: Number(tx.amount) || 0,
            date: (tx.date ?? new Date().toISOString()).toString(),
            note: (tx.note ?? '').toString(),
            excluded: Boolean(tx.excluded),
            assetId: (tx.assetId as number) ?? 0,
          });
        }
        const assetResult = await AccountingDB.getAssetAccount([]);
        const assetReport: AssetReport = assetResult as AssetReport;
        const assetList = assetReport.assets;
        const existingAssets: AssetTableBasis[] = data.assets?.length ? assetList : [];
        const existingAssetIds = new Set(existingAssets.map((a: AssetTableBasis) => a.assetId));
        const cloudAssets: AssetTableBasis[] = (data.assets || []) as AssetTableBasis[];
        for (const asset of cloudAssets) {
          if (asset.assetId != null && !existingAssetIds.has(asset.assetId)) {
            await AccountingDB.addAssetAccount(asset);
          }
        }
        // Save serverTime for next incremental sync
        const serverTime = Number(data.serverTime) || 0;
        if (serverTime > 0) {
          AuthCache.setLastSyncTime(serverTime);
        }
        if (pushSuccess) {
          ToastDialog.showToast({ message: '同步成功' });
        } else {
          ToastDialog.showToast({ message: '部分数据同步失败，请稍后重试' });
        }
      } else {
        ToastDialog.showToast({ message: res.msg || '同步失败' });
      }
    } catch (err) {
      ToastDialog.showToast({ message: '同步失败' });
    }
  }

  async doLogout() {
    AuthCache.clear();
    iData.global.isLogin = false;
    iData.global.userInfo.reset();
    RouterModule.clear();
    RouterModule.push({ url: RouterMap.USER_LOGIN });
    ToastDialog.showToast({ message: '已退出登录' });
  }
}
