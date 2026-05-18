import { ToastDialog } from '@hw-agconnect/ui-toast';
import { AssetCategory, AssetRecordItem } from 'asset_base';
import {
  AccountingDB,
  AssetManageUtil,
  AssetProcessingModel,
  BillProcessingModel,
} from 'bill_data_processing';
import { RouterMap, RouterModule } from 'commonlib';

@ObservedV2
export class AssetDetailVM {
  @Trace assetItem: AssetRecordItem | undefined = undefined;
  @Trace assetProcessing: AssetProcessingModel = new AssetProcessingModel();
  @Trace billProcessing: BillProcessingModel = new BillProcessingModel();

  @Computed
  public get totalAmount() {
    if (this.assetItem) {
      if (this.assetItem.category === AssetCategory.ASSET) {
        return this.assetProcessing.assetSummary.totalAsset;
      }
      return this.assetProcessing.assetSummary.totalLiability;
    }
    return 0;
  }

  public initData() {
    this.billProcessing.accountProcessing.init();
    const param = RouterModule.getNavParam<AssetRecordItem>({
      url: RouterMap.ASSET_BILL_DETAIL,
    });
    if (param) {
      this.assetItem = param;
      this.assetProcessing.getAssetReport(param.assetId);
      this.billProcessing.getBillReportByAsset(param.assetId);
    }
  }

  public initDataMock() {
    this.assetItem = {
      assetId: 0,
      name: '支付宝',
      icon: $r('app.media.ic_asset_1'),
      type: 1,
      subType: 1,
      category: 1,
      amount: 1000,
      note: '余额宝',
    };
    this.billProcessing.previewMock();
  }

  public async refreshData() {
    if (this.assetItem) {
      const assetId = this.assetItem.assetId;
      await this.assetProcessing.getAssetReport(assetId);
      await this.billProcessing.getBillReportByAsset(assetId);
      this.assetItem.amount = this.totalAmount;
    }
  }

  public editAsset() {
    if (!this.assetItem) {
      return;
    }
    AssetManageUtil.openManageSheet(
      {
        type: this.assetItem.type,
        initAsset: this.assetItem,
        handleEditSuccess: () => {
          this.refreshData();
        },
        handleDelete: (id) => {
          this.deleteAsset(id);
        },
      },
      this.assetItem.subType,
    );
  }

  public async deleteAsset(id: number) {
    await AccountingDB.deleteAssetAccount(id);
    ToastDialog.showToast({ message: '资产账户删除成功~' });
    RouterModule.pop(1);
  }
}
