import { AssetRecordItemModel, AssetDisplayTypeItem, AssetRecordItem, AssetType, Logger } from 'asset_base';
import { assetCreateSheetBuilder } from '../components/AssetCreateSheet';
import { assetInfoManageSheetBuilder } from '../components/AssetInfoManageSheet';

const TAG = '[PreviewPage]'

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
struct PreviewPage {
  @Local showCreateSheet: boolean = false;
  @Local showManageSheet: boolean = false;
  @Local manageItem: AssetDisplayTypeItem | undefined = undefined;
  @Local assetList: AssetRecordItemModel[] = [];
  @Local initAsset: AssetRecordItem | undefined = undefined;

  build() {
    Column({ space: 16 }) {
      Button('添加资产').onClick(() => {
        this.showCreateSheet = true;
      })
        .bindSheet($$this.showCreateSheet,
          assetCreateSheetBuilder({
            assetTypeList: MOCK_ASSET_TYPE_LIST,
            handleClick: (type: AssetType, subType?: number) => {
              this.openManageSheet(type, subType);
            },
          }), {
            title: { title: '选择资产类型' },
          });

      List({ space: 12 }) {
        ListItem() {
          Row() {
            Text('编号').width('20%');
            Text('名称').width('20%');
            Text('备注').width('20%');
            Text('金额').width('20%');
            Text('操作').width('20%');
          }.width('100%');
        };

        ForEach(this.assetList, (asset: AssetRecordItemModel) => {
          ListItem() {
            Row() {
              Text(asset.assetId!.toString()).width('20%');
              Text(asset.name).width('20%');
              Text(asset.note).width('20%');
              Text(asset.amount.toFixed(2)).width('20%');
              Text('编辑').width('20%').fontColor(Color.Blue).onClick(() => {
                this.editAsset(asset);
              });
            };
          };
        }, (item: AssetRecordItemModel) => JSON.stringify(item));
      }
      .width('100%')
      .layoutWeight(1);
    }
    .padding(16)
    .backgroundColor('#eee')
    .justifyContent(FlexAlign.Start)
    .bindSheet($$this.showManageSheet,
      assetInfoManageSheetBuilder({
        assetTypeItem: this.manageItem,
        initAsset: this.initAsset,
        type: this.manageItem?.type,
        handleConfirm: (data) => {
          this.confirmManage(data);
        },
        handleDelete: (id) => {
          this.deleteAsset(id);
        },
      }), {
        title: { title: '新增资产' },
        onWillDismiss: (action) => {
          this.initAsset = undefined;
          action.dismiss();
        },
      });
  }

  openManageSheet(type: AssetType, subType?: number) {
    console.log('点击了某一项资产，资产类型为' + subType);
    if (subType) {
      const item = MOCK_ASSET_TYPE_LIST.find((it) => it.subType === subType);
      this.manageItem = item!;
    } else {
      this.manageItem = undefined;
    }

    this.showManageSheet = true;
  }

  confirmManage(data: AssetRecordItemModel) {
    if (data.assetId) {
      let idx = this.assetList.findIndex((item) => item.assetId === data.assetId);
      this.assetList[idx] = data;
    } else {
      data.assetId = this.assetList.length + 1;
      this.assetList.push(data);
    }

    this.showManageSheet = false;
    this.showCreateSheet = false;
  }

  editAsset(item: AssetRecordItemModel) {
    const displayItem: AssetRecordItem = {
      assetId: item.assetId!,
      name: item.name,
      icon: '',
      type: item.type,
      subType: item.subType,
      category: item.category,
      amount: Number(item.amount),
      note: item.note,
      isCustom: item.isCustom,
    };
    this.initAsset = displayItem;
    this.showManageSheet = true;
  }

  deleteAsset(id: number) {
    const idx = this.assetList.findIndex((item) => item.assetId === id);
    if (typeof idx === 'number') {
      this.assetList.splice(idx, 1);
    }
    try {
      this.getUIContext().getPromptAction().showToast({ message: '删除成功' });
    } catch (err) {
      Logger.error(TAG, 'show toast failed. error:' + JSON.stringify(err));
    }
    this.showManageSheet = false;
  }
}