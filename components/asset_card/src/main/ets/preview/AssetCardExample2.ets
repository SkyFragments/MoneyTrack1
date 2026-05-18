import { AssetCategory, AssetGroupModel, AssetRecordItem, AssetType } from 'asset_base';
import { AssetCard } from '../components/AssetCard';

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
struct AssetCardExample2 {
  @Local
  anonymous: boolean = false;
  @Local
  assetData: AssetGroupModel = new AssetGroupModel();

  aboutToAppear(): void {
    this.assetData.fund = MOCK_FUND_LIST;
  }

  build() {
    Column({ space: 16 }) {
      Button('切换隐匿效果').onClick(() => {
        this.anonymous = !this.anonymous;
      });

      AssetCard({
        assetData: this.assetData,
        anonymous: this.anonymous,
      });
    }
    .padding(16)
    .backgroundColor('#eee');
  }
}