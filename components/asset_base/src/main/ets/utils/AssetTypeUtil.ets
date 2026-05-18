import { PersistenceV2 } from '@kit.ArkUI';
import { deviceInfo } from '@kit.BasicServicesKit';
import { AssetConstants } from '../commons/Constants';
import { AssetCategory, AssetType } from '../commons/Enums';
import { AssetTypeListModel, AssetTypeItemModel } from '../commons/Models';
import { AssetDisplayTypeItem } from '../commons/Types';

@ObservedV2
class AssetTypeUtil {
  @Trace private _typeList: AssetTypeListModel;

  @Computed
  public get displayTypeList(): AssetDisplayTypeItem[] {
    const list = this._typeList.list.map((item) => {
      const initItem = AssetConstants.ASSET_TYPE_MAP.find(
        (it) => item.subType === it.subType,
      );
      const displayItem: AssetDisplayTypeItem = {
        name: item.name,
        type: item.type,
        subType: item.subType,
        category: item.category,
        icon: initItem?.icon ?? '',
        isCustom: item.isCustom,
      };
      return displayItem;
    });
    return list;
  }

  constructor() {
    if (!deviceInfo.deviceType) {
      this._typeList = new AssetTypeListModel();
    } else {
      this._typeList = PersistenceV2.connect(
        AssetTypeListModel,
        () => new AssetTypeListModel(),
      )!;
    }
    this.getTypeList();
  }

  public getTypeList() {
    if (!this._typeList.list.length) {
      this._createTypeList();
    }
    return this._typeList;
  }

  public getTypeItem(subType: number) {
    const item = AssetConstants.ASSET_TYPE_MAP.find(
      (it) => it.subType === subType,
    );
    return item;
  }

  private _createTypeList() {
    AssetConstants.ASSET_TYPE_MAP.forEach((item) => {
      const type = this._createTypeModel(
        item.name,
        item.type,
        item.subType,
        item.category,
      );
      this._typeList.list.push(type);
    });
  }

  private _createTypeModel(
    name: string,
    type: AssetType,
    subType: number,
    category: AssetCategory,
  ) {
    const newItem = new AssetTypeItemModel();
    newItem.name = name;
    newItem.type = type;
    newItem.subType = subType;
    newItem.category = category;
    return newItem;
  }
}

const assetTypeUtil = new AssetTypeUtil();

export { assetTypeUtil as AssetTypeUtil };
