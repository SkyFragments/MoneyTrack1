import { UIDialog } from '@hw-agconnect/ui-dialog';
import { ToastDialog } from '@hw-agconnect/ui-toast';
import { AccountType, BreakpointSystem, BreakpointTypeEnum, Logger } from 'bill_base';
import { AccountingDB, AccountManageUtil, AccountProcessingModel, AccountTableBasis } from 'bill_data_processing';
import { CommonHeader, EventBus, EventKey, RouterMap, RouterModule } from 'commonlib';

const TAG = '[AccountBookPage]'

@Builder
export function accountBookPageBuilder() {
  AccountBookPage();
}

@ComponentV2
struct AccountBookPage {
  @Local accountModel: AccountProcessingModel = new AccountProcessingModel();
  @Local listScroller: ListScroller = new ListScroller();
  @Local isSwipeActionOpen: boolean = false;

  async aboutToAppear(): Promise<void> {
    await this.accountModel.init();
    EventBus.instance.on(EventKey.GLOBAL_REFRESH_EVENT, () => {
      this.refreshAccounts();
    });
  }

  aboutToDisappear(): void {
    EventBus.instance.off(EventKey.GLOBAL_REFRESH_EVENT, () => {
      this.refreshAccounts();
    });
  }

  @Computed
  get lanesValue() {
    if (BreakpointSystem.currentBreakpoint.value === BreakpointTypeEnum.SM) {
      return 1;
    } else if (BreakpointSystem.currentBreakpoint.value === BreakpointTypeEnum.MD) {
      return 2;
    } else {
      return 3;
    }
  }

  private async refreshAccounts() {
    try {
      await this.accountModel.loadAccounts();
    } catch (err) {
      Logger.error(TAG, 'refresh accounts failed. error:' + JSON.stringify(err));
    }
  }

  onBackPress(): boolean {
    if (this.isSwipeActionOpen) {
      try {
        this.listScroller.closeAllSwipeActions();
      } catch (err) {
        Logger.error(TAG, 'close swipeActions failed. error:' + JSON.stringify(err));
      }
      return true;
    } else {
      return false;
    }
  }

  build() {
    NavDestination() {
      CommonHeader({ title: '账本' });

      // 账本列表
      List({ space: 12, scroller: this.listScroller }) {
        // 1. 默认账本部分
        if (this.accountModel.accounts.some(acc => acc.type === AccountType.DEFAULT)) {
          ListItemGroup({ header: this.listHeader('默认账本') }) {
            ForEach(this.accountModel.accounts.filter(acc => acc.type === AccountType.DEFAULT),
              (item: AccountTableBasis) => {
              ListItem() {
                this.accountItemBuilder(item)
              }
            }, (item: AccountTableBasis) => item.accountId.toString())
          }
        }
        // 2. 其它账本部分
        if (this.accountModel.accounts.some(acc => acc.type === AccountType.CUSTOM)) {
          ListItemGroup({ header: this.listHeader('其它账本'), space: 12 }) {
            ForEach(this.accountModel.accounts.filter(acc => acc.type === AccountType.CUSTOM),
              (item: AccountTableBasis) => {
              ListItem() {
                this.accountItemBuilder(item)
              }
              .swipeAction({
                end: {
                  builder: this.customItemSwipeActions(item),
                  onAction: () => {
                    UIDialog.open({
                      contentOptions: {
                        content: '删除后将无法恢复，是否删除？',
                        contentTextAlign: TextAlign.Center
                      },
                      showConfirmButton: true,
                      showCancelButton: true,
                      confirmButtonOptions: {
                        button: '删除',
                        buttonFontColor: $r('app.color.icon_color_warning'),
                      },
                      cancelButtonOptions: {
                        buttonFontColor: $r('app.color.font_color_level1'),
                      },
                      onConfirm: () => this.deleteAccount(item.accountId),
                    })
                  },
                  onStateChange: (state: SwipeActionState) => {
                    if (state !== SwipeActionState.COLLAPSED) {
                      this.isSwipeActionOpen = true;
                    } else {
                      this.isSwipeActionOpen = false;
                    }
                  }
                }
              })
            }, (item: AccountTableBasis) => item.accountId.toString())
          }
        }
      }
      .width('100%')
      .lanes(this.lanesValue, 12)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .layoutWeight(1)

      Button('新建账本')
        .width('100%')
        .height(48)
        .fontSize($r('sys.float.Body_L'))
        .backgroundColor($r('app.color.system_theme_color'))
        .onClick(() => {
          AccountManageUtil.openAddAccountSheet(async () => {
            await this.accountModel.loadAccounts();
          });
        })
    }
    .onBackPressed(() => this.onBackPress())
    .hideTitleBar(true)
    .padding($r('app.string.space_l'))
    .backgroundColor($r('app.color.system_color_background_auxiliary'))
    .onHidden(() => {
      this.accountModel = new AccountProcessingModel();
    })
    .onWillShow(async () => {
      await this.accountModel.init();
    })
  }

  @Builder
  listHeader(title: string) {
    Text(title)
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('app.color.font_color_level2'))
      .width('100%')
      .padding({ top: 8, bottom: 8 })
  }

  @Builder
  accountItemBuilder(item: AccountTableBasis) {
    Row() {
      Image($r('app.media.ic_account_icon'))
        .width(32)
        .height(32)
        .margin({ right: 16 })

      Column({ space: 4 }) {
        Row({ space: 4 }) {
          Text(item.name)
            .fontSize(16)
            .fontColor($r('app.color.font_color_level1'))
            .fontWeight(FontWeight.Medium)
          if (item.type === AccountType.DEFAULT) {
            Image($r('app.media.ic_account_label'))
              .width(28)
              .height(16)
          }
        }

        Text(`共${item.transactionCount ?? 0}笔账单`)
          .fontSize(12)
          .fontColor($r('app.color.font_color_level2'))

        Row() {
          Text(`支 ${item.accountExpense.toFixed(2)}`)
            .fontSize(12)
            .fontColor($r('app.color.font_color_level2'))
          Text(`/收 ${item.accountIncome.toFixed(2)}`)
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
        Text(`${(item.accountIncome - item.accountExpense).toFixed(2)}`)
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
    .border({
      width: item.type === AccountType.DEFAULT ? 2 : 0,
      color: $r('app.color.system_theme_color')
    })
    .borderRadius($r('app.string.border_radius_m'))
    .onClick(() => {
      RouterModule.push({
        url: RouterMap.HOME_ACCOUNT_BOOK_DETAIL,
        param: item
      })
    })
  }

  @Builder
  customItemSwipeActions(item: AccountTableBasis) {
    Row() {
      Text('设为默认')
        .fontSize(14)
        .fontColor($r('app.color.font_color_level1_invert'))
        .height(96)
        .width(72)
        .textAlign(TextAlign.Center)
        .backgroundColor($r('sys.color.comp_background_emphasize'))
        .onClick(() => {
          this.setDefaultAccount(item);
        })
      Text('删除')
        .fontSize(14)
        .fontColor($r('app.color.font_color_level1_invert'))
        .height(96)
        .width(72)
        .textAlign(TextAlign.Center)
        .backgroundColor($r('sys.color.warning'))
        .borderRadius({ topRight: 16, bottomRight: 16 })
        .onClick(() => {
          UIDialog.open({
            contentOptions: {
              content: '删除后将无法恢复，是否删除？',
              contentTextAlign: TextAlign.Center
            },
            showConfirmButton: true,
            showCancelButton: true,
            confirmButtonOptions: {
              button: '删除',
              buttonFontColor: $r('app.color.icon_color_warning'),
            },
            cancelButtonOptions: {
              buttonFontColor: $r('app.color.font_color_level1'),
            },
            onConfirm: () => this.deleteAccount(item.accountId),
          })
        })
    }
    .height(96)
  }

  private async setDefaultAccount(item: AccountTableBasis) {
    const updateData: AccountTableBasis = {
      accountId: item.accountId,
      type: AccountType.DEFAULT,
      name: item.name,
      date: item.date,
      accountIncome: item.accountIncome,
      accountExpense: item.accountExpense,
    };
    await AccountingDB.editAccount(updateData);
    ToastDialog.showToast({ message: '已设为默认账本' });
    EventBus.instance.emit(EventKey.GLOBAL_REFRESH_EVENT);
  }

  private async deleteAccount(accountId: number) {
    await AccountingDB.deleteAccount(accountId);
    EventBus.instance.emit(EventKey.GLOBAL_REFRESH_EVENT);
  }
}

