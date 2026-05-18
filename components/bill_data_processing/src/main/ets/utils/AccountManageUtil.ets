import { ToastDialog } from '@hw-agconnect/ui-toast';
import { Logger } from 'bill_base';
import { Constants } from 'asset_base';
import { EventBus, EventKey } from 'commonlib';
import { AccountingDB } from './accountingdb/AccountingDB';
import { AccountTableBasis } from './accountingdb/Types';
import { PopViewUtil } from './PopViewUtil';
import { AccountInfoManageOptions, accountInfoManageSheetBuilder } from '../components/AccountManageSheet';

const TAG = '[AccountManageUtil]';

@ObservedV2
class AccountManageUtil {
  public openAddAccountSheet(onSuccess?: () => void) {
    PopViewUtil.openSheet(
      wrapBuilder(accountInfoManageSheetBuilder),
      {
        detents: [SheetSize.MEDIUM],
        preferType: SheetType.CENTER,
        title: { title: '新建账本' },
        backgroundColor: Constants.BACKGROUND_COLOR_GREY,
      },
      {
        initAccount: undefined,
        handleConfirm: async (data: AccountTableBasis) => {
          await this._createAccount(data);
          onSuccess?.();
        },
      } as AccountInfoManageOptions,
    );
  }

  public openEditAccountSheet(account: AccountTableBasis, onSuccess?: () => void) {
    PopViewUtil.openSheet(
      wrapBuilder(accountInfoManageSheetBuilder),
      {
        detents: [SheetSize.MEDIUM],
        preferType: SheetType.CENTER,
        title: { title: '编辑账本' },
        backgroundColor: Constants.BACKGROUND_COLOR_GREY,
      },
      {
        initAccount: account,
        handleConfirm: async (data: AccountTableBasis) => {
          await this._editAccount(account, data);
          onSuccess?.();
        },
      } as AccountInfoManageOptions,
    );
  }

  private async _createAccount(data: AccountTableBasis) {
    try {
      await AccountingDB.addAccount(data);
      EventBus.instance.emit(EventKey.GLOBAL_REFRESH_EVENT);
      PopViewUtil.closeAllSheet();
    } catch (err) {
      Logger.error(TAG, 'create account failed.' + JSON.stringify(err));
      if (JSON.stringify(err).includes('UNIQUE')) {
        ToastDialog.showToast({ message: '账本名称已存在' });
      }
    }
  }

  private async _editAccount(oldAccount: AccountTableBasis, newData: AccountTableBasis) {
    try {
      await AccountingDB.editAccount(newData);
      EventBus.instance.emit(EventKey.GLOBAL_REFRESH_EVENT);
      PopViewUtil.closeAllSheet();
    } catch (err) {
      Logger.error(TAG, 'edit account failed.' + JSON.stringify(err));

      const errMsg = JSON.stringify(err);
      if (errMsg.includes('Must keep at least one default account')) {
        ToastDialog.showToast({ message: '至少保留一个默认账本' });
      }
      else if (errMsg.includes('UNIQUE')) {
        ToastDialog.showToast({ message: '账本名称已存在' });
      }
      else {
        ToastDialog.showToast({ message: '账本保存失败' });
      }
    }
  }
}

const util = new AccountManageUtil();

export { util as AccountManageUtil };
