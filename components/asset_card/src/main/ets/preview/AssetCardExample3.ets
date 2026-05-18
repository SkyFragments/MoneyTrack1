import { AssetCategory, AssetGroupModel, AssetRecordItem, AssetType, Logger } from 'asset_base';
import { AssetCard } from '../components/AssetCard';

const TAG = '[AssetCardExample3]'

const MOCK_FUND_LIST: AssetRecordItem[] = [
  {
    assetId: 0,
    name: '支付宝',
    icon: $r('app.media.ic_asset_4'),
    type: AssetType.FUND,
    subType: 1,
    category: AssetCategory.ASSET,
    amount: 1000,
    note: '余额宝',
  },
];

@Entry
@ComponentV2
struct AssetCardExample3 {
  @Local
  anonymous: boolean = false;
  @Local
  assetData: AssetGroupModel = new AssetGroupModel();

  aboutToAppear(): void {
    this.assetData.fund = MOCK_FUND_LIST;
  }

  build() {
    Column({ space: 16 }) {
      Button('添加资产').onClick(() => {
        const assetId = this.assetData.fund.length;
        const newItem: AssetRecordItem = {
          assetId: assetId,
          name: '自定义' + assetId,
          icon: $r('app.media.ic_asset_others'),
          type: AssetType.FUND,
          subType: 1,
          category: AssetCategory.ASSET,
          amount: 1000,
          note: '测试',
        };
        this.assetData.fund.push(newItem);
      });

      AssetCard({
        assetData: this.assetData,
        handleClick: (item) => {
          try {
            this.getUIContext().getPromptAction().showToast({
              message: `点击了资产账户${item.name},余额为${item.amount}元`,
              alignment: Alignment.Center,
            });
          } catch (err) {
            Logger.error(TAG, 'show toast failed. error:' + JSON.stringify(err));
          }
        },
        handleDelete: (id) => {
          const idx = this.assetData.fund.findIndex((item) => item.assetId === id);
          if (idx) {
            this.assetData.fund.splice(idx, 1);
          }
        },
      });
    }
    .padding(16)
    .backgroundColor('#eee');
  }
}