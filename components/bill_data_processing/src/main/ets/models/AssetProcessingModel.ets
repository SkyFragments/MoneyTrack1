import {
  AssetGroup,
  AssetRecordItem,
  AssetSummary,
  AssetType,
  AssetTypeUtil,
} from 'asset_base';
import { AccountingDB } from '../utils/accountingdb/AccountingDB';
import { AssetTableFields } from '../utils/accountingdb/Enums';
import {
  UserTablePredicateParams,
  AssetTableBasis,
  AssetReport,
} from '../utils/accountingdb/Types';
import { DBOperator } from '../utils/basedb/Constants';

@ObservedV2
export class AssetProcessingModel {
  @Trace report: AssetReport | undefined = undefined;

  @Computed
  public get assetSummary(): AssetSummary {
    return {
      totalAsset: this.report?.totalAsset ?? 0,
      totalLiability: this.report?.totalLiability ?? 0,
    };
  }

  @Computed
  public get assetGroup(): AssetGroup {
    if (this.report) {
      const fund: AssetRecordItem[] = this.report.assets
        .filter((item) => item.type === AssetType.FUND)
        .map((item) => {
          return this.getAssetRecordItem(item);
        });
      const credit: AssetRecordItem[] = this.report.assets
        .filter((item) => item.type === AssetType.CREDIT)
        .map((item) => {
          return this.getAssetRecordItem(item);
        });
      return {
        fund,
        credit,
      };
    }
    return {
      fund: [],
      credit: [],
    };
  }

  public async getAssetReport(assetId?: number) {
    const condition: UserTablePredicateParams[] = [];
    if (typeof assetId === 'number') {
      const assetIdCondition: UserTablePredicateParams = {
        field: AssetTableFields.ASSET_ID,
        value: assetId,
        operator: DBOperator.EQUAL,
      };
      condition.push(assetIdCondition);
    }
    this.report = await AccountingDB.getAssetAccount(condition);
  }

  public getAssetRecordItem(item: AssetTableBasis): AssetRecordItem {
    const typeItem = AssetTypeUtil.getTypeItem(item.subType);
    const icon =
      typeItem?.icon ??
      (item.type === AssetType.FUND
        ? $r('app.media.ic_asset_others')
        : $r('app.media.ic_liability_others'));
    const recordItem: AssetRecordItem = {
      assetId: item.assetId,
      name: item.name,
      icon,
      type: item.type,
      subType: item.subType,
      category: item.category,
      amount: item.amount,
      note: item.note,
    };
    return recordItem;
  }
}
