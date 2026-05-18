import { Type } from '@kit.ArkUI';
import { AssetType, AssetCategory } from './Enums';
import { AssetGroup, AssetRecordItem, AssetTypeItem } from './Types';

@ObservedV2
export class AssetGroupModel implements AssetGroup {
  @Trace fund: AssetRecordItem[] = [];
  @Trace credit: AssetRecordItem[] = [];
}

export class AssetTypeItemModel implements AssetTypeItem {
  name: string = '';
  type: AssetType = AssetType.FUND;
  subType: number = -1;
  category: AssetCategory = AssetCategory.ASSET;
  isCustom?: boolean;
}

@ObservedV2
export class AssetTypeListModel {
  @Type(AssetTypeItemModel)
  @Trace
  list: AssetTypeItemModel[] = [];
}

@ObservedV2
export class AssetRecordItemModel implements AssetRecordItem {
  @Trace assetId: number = 0;
  @Trace name: string = '';
  @Trace icon: ResourceStr = '';
  @Trace type: AssetType = AssetType.FUND;
  @Trace subType: number = -1;
  @Trace category: AssetCategory = AssetCategory.ASSET;
  @Trace note: string = '';
  @Trace amount: number = 0;
  @Trace isCustom: boolean = false;
}
