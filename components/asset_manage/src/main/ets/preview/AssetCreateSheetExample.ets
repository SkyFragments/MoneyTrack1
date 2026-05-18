import { AssetDisplayTypeItem, AssetType, Logger } from 'asset_base';
import { AssetCreateSheet, assetCreateSheetBuilder } from '../components/AssetCreateSheet';

const TAG = '[AssetCreateSheetExample1]'

const MOCK_ASSET_TYPE_LIST: AssetDisplayTypeItem[] = [
  {
    name: '现金',
    type: 1,
    subType: 101,
    category: 1,
    icon: $r('app.media.ic_asset_1'),
  },
  {
    name: '银行卡',
    type: 1,
    subType: 102,
    category: 1,
    icon: $r('app.media.ic_asset_2'),
  },
  {
    name: '信用卡',
    type: 2,
    subType: 201,
    category: 2,
    icon: $r('app.media.ic_liability_1'),
  },
];

@Entry
@ComponentV2
struct AssetCreateSheetExample1 {
  @Local showCreateSheet: boolean = false;

  build() {
    Column({ space: 24 }) {
      Text('使用方式1：直接使用组件嵌入页面');
      AssetCreateSheet({
        assetTypeList: MOCK_ASSET_TYPE_LIST,
        handleClick: (type: AssetType, subType?: number) => {
          try {
            this.getUIContext().getPromptAction().showToast({
              message: '点击了类型为' + type + '子类型为' + subType + '的资产按钮',
            });
          } catch (err) {
            Logger.error(TAG, 'show toast failed. error:' + JSON.stringify(err));
          }
        },
      }).height(300);
      Text('使用方式2：使用bindSheet拉起半模态弹框使用');
      Button('打开')
        .onClick(() => {
          this.showCreateSheet = !this.showCreateSheet;
        })
        .bindSheet($$this.showCreateSheet,
          assetCreateSheetBuilder({
            assetTypeList: MOCK_ASSET_TYPE_LIST,
          }), {
            title: { title: '选择资产类型' },
            detents: [SheetSize.MEDIUM],
          });
    }
    .backgroundColor('#eee')
    .padding(16);
  }
}