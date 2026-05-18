export enum AssetType {
  FUND = 1, // 资金账户
  CREDIT = 2, // 信用账户
}

export enum AssetCategory {
  ASSET = 1, // 资产
  LIABILITY = 2, // 负债
}

export enum AssetChangeType {
  NET_ASSET = 'netAsset', // 净资产
  LIABILITY = 'liability', // 负债
}

export enum TimeRangeType {
  YEAR = 'year', // 年视图
  MONTH = 'month', // 月视图
}