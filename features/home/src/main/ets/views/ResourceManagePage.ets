import { AccountingDB } from 'bill_data_processing';
import { resourceManageSheetBuilder } from 'bill_manage';
import { CommonHeader } from 'commonlib';

@Builder
export function resourceManagePageBuilder() {
  ResourceManagePage();
}

@Entry
@ComponentV2
struct ResourceManagePage {
  build() {
    NavDestination() {
      CommonHeader({ title: '分类管理' });

      resourceManageSheetBuilder({
        handleDeleteSuccess:async (key) => {
          await AccountingDB.deleteTransactionsByResource(key);
        },
      });
    }
    .hideTitleBar(true)
    .padding($r('app.string.space_l'))
    .backgroundColor($r('app.color.system_color_background_auxiliary'))
  }
}

