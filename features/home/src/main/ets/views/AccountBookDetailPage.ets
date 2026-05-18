import { UIDialog } from '@hw-agconnect/ui-dialog';
import { ToastDialog } from '@hw-agconnect/ui-toast';
import { AccountType, Logger } from 'bill_base';
import { AccountingDB, AccountManageUtil, AccountTableBasis } from 'bill_data_processing';
import { CommonHeader, RouterMap, RouterModule, EventBus, EventKey, CommonDayPicker } from 'commonlib';

const TAG = '[AccountBookDetailPage]';

@Builder
export function accountBookDetailPageBuilder() {
  AccountBookDetailPage();
}

@ComponentV2
struct AccountBookDetailPage {
  @Local accountData: AccountTableBasis | null = null;
  @Local currentAccountId: number = 0;

  private refreshHandler = () => {
    if (this.currentAccountId > 0) {
      this.loadAccountData(this.currentAccountId);
    }
  };

  aboutToAppear(): void {
    const navData = RouterModule.getNavParam<AccountTableBasis>({
      url: RouterMap.HOME_ACCOUNT_BOOK_DETAIL,
    });

    if (navData && navData.accountId) {
      this.currentAccountId = navData.accountId;
      this.loadAccountData(this.currentAccountId);
    }
    EventBus.instance.on(EventKey.GLOBAL_REFRESH_EVENT, this.refreshHandler);
  }

  aboutToDisappear(): void {
    EventBus.instance.off(EventKey.GLOBAL_REFRESH_EVENT, this.refreshHandler);
  }

  // 根据 ID 重新加载账本数据
  private async loadAccountData(accountId: number) {
    try {
      const allAccounts = await AccountingDB.getAccounts();
      const target = allAccounts.find(acc => acc.accountId === accountId);

      if (target) {
        this.accountData = target;
        this.currentAccountId = target.accountId;
      } else {
        this.accountData = null;
      }
    } catch (err) {
      Logger.error(TAG, 'load account data failed.' + JSON.stringify(err));
    }
  }

  // 处理保存账本信息
  private async saveAccountData(updatedData: AccountTableBasis) {
    if (!this.accountData) {
      return;
    }
    try {
      await AccountingDB.editAccount(updatedData);
      await this.loadAccountData(updatedData.accountId);
      EventBus.instance.emit(EventKey.GLOBAL_REFRESH_EVENT);
    } catch (err) {
      Logger.error(TAG, 'update account failed.' + JSON.stringify(err));
      const errMsg = err instanceof Error ? err.message : JSON.stringify(err);
      if (errMsg.includes('Must keep at least one default account')) {
        ToastDialog.showToast({ message: '至少保留一个默认账本' });
      } else {
        ToastDialog.showToast({ message: '修改失败，请稍后重试' });
      }
    }
  }

  build() {
    NavDestination() {
      CommonHeader({
        title: '账本详情',
        icon: $r('app.media.ic_account_detail'),
        iconClick: () => {
          if (this.accountData) {
            AccountManageUtil.openEditAccountSheet(this.accountData)
          }
        }
      });

      if (this.accountData) {
        Column({ space: 12 }) {
          Row() {
            Image($r('app.media.ic_account_icon'))
              .width(32)
              .height(32)
              .margin({ right: 16 })
            Column({ space: 4 }) {
              Row({ space: 4 }) {
                Text(this.accountData.name)
                  .fontSize(16)
                  .fontColor($r('app.color.font_color_level1'))
                  .fontWeight(FontWeight.Medium)
                if (this.accountData.type === AccountType.DEFAULT) {
                  Image($r('app.media.ic_account_label'))
                    .width(28)
                    .height(16)
                }
              }
              Text(`共${this.accountData.transactionCount ?? 0}笔账单`)
                .fontSize(12)
                .fontColor($r('app.color.font_color_level2'))
              Row() {
                Text(`支 ${this.accountData.accountExpense.toFixed(2)}`)
                  .fontSize(12)
                  .fontColor($r('app.color.font_color_level2'))
                Text(`/收 ${this.accountData.accountIncome.toFixed(2)}`)
                  .fontSize(12)
                  .fontColor($r('app.color.font_color_level2'))
              }
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            // 结余
            Column({ space: 4 }) {
              Text('结余')
                .fontSize(12)
                .fontColor($r('app.color.font_color_level2'))
              Text(`${(this.accountData.accountIncome - this.accountData.accountExpense).toFixed(2)}`)
                .fontSize(16)
                .fontColor($r('app.color.font_color_level1'))
                .fontWeight(FontWeight.Medium)
            }
            .alignItems(HorizontalAlign.End)
          }
          .width('100%')
          .height(96)
          .padding({ left: 12, right: 12 })
          .backgroundColor($r('sys.color.comp_background_list_card'))
          .borderRadius($r('app.string.border_radius_m'))

          Row() {
            Column({ space: 2 }) {
              Text('每月开始日')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.font_color_level1'))
                .textAlign(TextAlign.Start)
              Text('每月账单统计开始日')
                .fontSize(12)
                .fontColor($r('app.color.font_color_level2'))
                .textAlign(TextAlign.Start)
            }.alignItems(HorizontalAlign.Start)
            Row({ space: 4 }) {
              Text(`${this.accountData.date}日`)
                .fontColor($r('app.color.font_color_level1'))
                .fontSize(14)
              Image($r('app.media.ic_arrow_right_small'))
                .width(12)
                .height(24)
                .onClick(() => {
                  UIDialog.open({
                    contentBuilder: () => this.dayPickerDialog()
                  })
                });
            }
          }.formRowStyle();

          Row() {
            Text('设置为默认账本')
              .fontColor($r('app.color.font_color_level1'))
              .fontWeight(FontWeight.Medium);
            Toggle({ type: ToggleType.Switch, isOn: this.accountData.type === AccountType.DEFAULT })
              .selectedColor($r('app.color.system_theme_color'))
              .onChange((isOn: boolean) => {
                const newType = isOn ? AccountType.DEFAULT : AccountType.CUSTOM;
                const updatedData: AccountTableBasis = {
                  accountId: this.accountData!.accountId,
                  name: this.accountData!.name,
                  type: newType,
                  date: this.accountData!.date,
                  accountIncome: this.accountData!.accountIncome,
                  accountExpense: this.accountData!.accountExpense
                };
                this.saveAccountData(updatedData);
              });
          }.formRowStyle();
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .hideTitleBar(true)
    .padding($r('app.string.space_l'))
    .backgroundColor($r('app.color.system_color_background_auxiliary'))
  }

  @Builder
  dayPickerDialog() {
    CommonDayPicker({
      initDay: this.accountData!.date,
      handleConfirm: (dayStr: string) => {
        const newDate = dayStr.padStart(2, '0');
        const updatedData: AccountTableBasis = {
          accountId: this.accountData!.accountId,
          name: this.accountData!.name,
          type: this.accountData!.type,
          date: newDate,
          accountIncome: this.accountData!.accountIncome,
          accountExpense: this.accountData!.accountExpense
        };
        this.saveAccountData(updatedData);
        UIDialog.closeLast();
      },
      handleCancel: () => {
        UIDialog.closeLast();
      }
    })
  }
}

@Extend(Row)
function formRowStyle() {
  .width('100%')
  .padding({ left: 12, right: 12, top: 8, bottom: 8 })
  .backgroundColor($r('sys.color.comp_background_list_card'))
  .borderRadius($r('app.string.border_radius_s'))
  .justifyContent(FlexAlign.SpaceBetween)
  .alignItems(VerticalAlign.Center);
}