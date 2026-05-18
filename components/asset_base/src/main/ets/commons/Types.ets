import { AssetCategory, AssetType } from './Enums';

export interface AssetRecordItem {
  assetId: number;
  name: string;
  icon: ResourceStr;
  type: AssetType;
  subType: number;
  category: AssetCategory;
  amount: number;
  note?: string;
  isCustom?: boolean;
}

export interface AssetSummary {
  totalAsset: number;
  totalLiability: number;
}

export interface AssetReportRsp extends AssetSummary {
  assets: AssetRecordItem[];
}

export interface AssetGroup {
  fund: AssetRecordItem[];
  credit: AssetRecordItem[];
}

export interface AssetTypeItem {
  name: string;
  type: AssetType;
  subType: number;
  category: AssetCategory;
  isCustom?: boolean;
}

export interface AssetDisplayTypeItem extends AssetTypeItem {
  icon: ResourceStr;
}

export interface AssetTrendItem {
  date: string; // 格式 YYYY-MM-DD
  value: number; // 当天的总资产
}

export interface AssetFilterState {
  selectedIds: Set<number>;
  isAllSelected: boolean;
}

export interface TransactionImpact {
  assetId: number;
  impact: number;
}

export interface AddAssetParam {
  type: AssetType;
  subType?: number;
}