import { AssetRecordItem, AssetGroupModel, AssetType, AssetCategory } from 'asset_base';
import { AssetCard } from '../components/AssetCard';
import { AssetSummaryCard } from '../components/AssetSummaryCard';

const MOCK_FUND_LIST: AssetRecordItem[] = [
  {
    assetId: 101,
    name: '支付宝',
    icon: $r('app.media.ic_asset_4'),
    type: AssetType.FUND,
    subType: 1,
    category: AssetCategory.ASSET,
    amount: 1000,
    note: '余额宝',
  },
  {
    assetId: 102,
    name: '微信',
    icon: $r('app.media.ic_asset_5'),
    type: AssetType.FUND,
    subType: 2,
    category: AssetCategory.ASSET,
    amount: 2000,
  },
];

const MOCK_CREDIT_LIST: AssetRecordItem[] = [
  {
    assetId: 201,
    name: '信用卡',
    icon: $r('app.media.ic_liability_1'),
    type: AssetType.CREDIT,
    subType: 1,
    category: AssetCategory.LIABILITY,
    amount: 300,
  },
];

@Entry
@ComponentV2
struct AssetSummaryCardExample1 {
  @Local
  anonymous: boolean = false;
  @Local
  assetData: AssetGroupModel = new AssetGroupModel();

  aboutToAppear(): void {
    this.setData();
  }

  setData() {
    this.assetData.fund = JSON.parse(JSON.stringify(MOCK_FUND_LIST));
    this.assetData.credit = JSON.parse(JSON.stringify(MOCK_CREDIT_LIST));
  }

  @Computed
  get totalAsset() {
    return this.assetData.fund.reduce((pre, cur) => pre + cur.amount, 0);
  }

  @Computed
  get totalLiability() {
    return this.assetData.credit.reduce((pre, cur) => pre + cur.amount, 0);
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Button('重置')
          .onClick(() => {
            this.setData();
          });
        // 总资产卡片
        AssetSummaryCard({
          anonymous: this.anonymous,
          handleEyeClick: () => {
            this.anonymous = !this.anonymous;
          },
          assetData: {
            totalAsset: this.totalAsset,
            totalLiability: this.totalLiability,
          },
        });
        // 资产卡片
        AssetCard({
          assetData: this.assetData,
          anonymous: this.anonymous,
          handleClick: (item: AssetRecordItem) => {
            console.log('当前选中的资产账户信息如下：' + JSON.stringify(item));
          },
          handleDelete: (id: number) => {
            if (id < 200) {
              const idx = this.assetData.fund.findIndex((item) => item.assetId === id);
              if (idx >= 0) {
                this.assetData.fund.splice(idx, 1);
              }
            } else {
              const idx = this.assetData.credit.findIndex((item) => item.assetId === id);
              if (idx >= 0) {
                this.assetData.credit.splice(idx, 1);
              }
            }
          },
        });
      }
      .padding(16)
      .backgroundColor('#eee');
    };
  }
}