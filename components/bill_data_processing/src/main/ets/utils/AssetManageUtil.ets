import { ToastDialog } from '@hw-agconnect/ui-toast';
import { emitter } from '@kit.BasicServicesKit';
import {
  AssetType,
  AssetTypeUtil,
  AssetRecordItemModel,
  AssetDisplayTypeItem,
} from 'asset_base';
import {
  assetCreateSheetBuilder,
  AssetCreateSheetOptions,
  AssetInfoManageParams,
  assetInfoManageSheetBuilder,
} from 'asset_manage';
import { Logger } from 'bill_base';
import { RouterMap, RouterModule } from 'commonlib';
import { ASSET_CHANGE_EVENT_ID } from '../commons/Constants';
import { AccountingDB } from './accountingdb/AccountingDB';
import { AssetTableBasis, UserAsset } from './accountingdb/Types';
import { PopViewUtil } from './PopViewUtil';

const TAG = '[AssetManageUtil]';

@ObservedV2
class AssetManageUtil {
  @Trace
  typeList: AssetDisplayTypeItem[] = AssetTypeUtil.displayTypeList;

  public openAddAssetSheet() {
    PopViewUtil.openSheet(
      wrapBuilder(assetCreateSheetBuilder),
      {
        detents: [SheetSize.MEDIUM],
        preferType: SheetType.CENTER,
        title: { title: '选择资产类型' },
        backgroundColor: $r('sys.color.background_primary'),
      },
      {
        assetTypeList: this.typeList,
        handleClick: (type: AssetType, subType?: number) => {
          PopViewUtil.closeAllSheet();
          this._navigateToAddAssetPage(type, subType);
        },
      } as AssetCreateSheetOptions,
    );
  }

  public openManageSheet(params: AssetInfoManageParams, subType?: number) {
    const typeItem = subType ? AssetTypeUtil.getTypeItem(subType) : undefined;

    PopViewUtil.openSheet(
      wrapBuilder(assetInfoManageSheetBuilder),
      {
        detents: [SheetSize.MEDIUM],
        preferType: SheetType.CENTER,
        title: { title: params.initAsset ? '编辑资产' : '添加资产' },
        backgroundColor: '#f1f3f5',
        onWillDismiss: (action) => {
          if (action.reason !== DismissReason.TOUCH_OUTSIDE) {
            PopViewUtil.closeSheet();
          }
        },
      },
      {
        assetTypeItem: typeItem,
        type: params.type,
        initAsset: params.initAsset,
        handleConfirm: async (newModel: AssetRecordItemModel) => {
          if (newModel.assetId) {
            await this._editAssetAccount(newModel);
            params.handleEditSuccess?.();
            return;
          }
          this._createAssetAccount(newModel);
        },
        handleEditSuccess: () => {
          params.handleEditSuccess?.();
        },
        handleDelete: (id: number) => {
          params.handleDelete?.(id);
          PopViewUtil.closeAllSheet();
        },
      } as AssetInfoManageParams,
    );
  }

  private _navigateToAddAssetPage(type: AssetType, subType?: number) {
    RouterModule.push({
      url: RouterMap.ADD_ASSET,
      param: { type, subType },
    });
  }

  private async _createAssetAccount(data: AssetRecordItemModel) {
    const userData: UserAsset = {
      name: data.name,
      type: data.type,
      subType: data.subType ?? 999,
      category: data.category,
      amount: Number(data.amount),
      note: data.note ?? '',
    };
    try {
      await AccountingDB.addAssetAccount(userData);
      emitter.emit({ eventId: ASSET_CHANGE_EVENT_ID });
      ToastDialog.showToast({ message: '资产账户添加成功~' });
      PopViewUtil.closeAllSheet();
    } catch (err) {
      Logger.error(TAG, 'create asset account failed.' + JSON.stringify(err));
    }
  }

  private async _editAssetAccount(data: AssetRecordItemModel) {
    const userData: AssetTableBasis = {
      assetId: data.assetId as number,
      name: data.name,
      type: data.type,
      subType: data.subType,
      category: data.category,
      amount: Number(data.amount),
      note: data.note ?? '',
    };
    try {
      await AccountingDB.editAssetAccount(userData);
      emitter.emit({ eventId: ASSET_CHANGE_EVENT_ID });
      ToastDialog.showToast({ message: '资产账户编辑成功~' });
      PopViewUtil.closeAllSheet();
    } catch (err) {
      Logger.error(TAG, 'edit asset account failed.' + JSON.stringify(err));
    }
  }
}

const util = new AssetManageUtil();

export { util as AssetManageUtil };
