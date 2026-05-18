import { BalanceChangeType, BillCardItem, DailyBillGroup } from 'bill_base';
import { BillCard, BillSummaryCard } from 'bill_card';
import { CreateBillButton } from 'bill_data_processing';
import { CommonHeader, CommonMonthPicker, EventBus, EventKey, BreakpointSystem, RouterMap, RouterModule } from 'commonlib';
import { HomeSheetType } from '../commons/Enums';
import { MonthlyBudgetCard } from '../components/MonthlyBudgetCard';
import { TypeFilterSheet } from '../components/TypeFilterSheet';
import { HomeVM } from '../viewmodels/HomeVM';

@ComponentV2
export struct HomeView {
  vm: HomeVM = new HomeVM();
  @Local showSheet: boolean = false;
  @Local isRefreshing: boolean = false;

  build() {
    Column() {
      CommonHeader({
        title: '明细',
        icon: $r('app.media.ic_account_book'),
        iconClick: () => { RouterModule.push({ url: RouterMap.HOME_ACCOUNT_BOOK }) }
      });
      Refresh({ refreshing: $$this.isRefreshing }) {
        Column() {
          // 筛选栏
          this.filterBarBuilder();
          Scroll() {
            Column() {
              // 收支概况
              BillSummaryCard({
                totalExpense: this.vm.dataProcessing.totalExpense,
                totalIncome: this.vm.dataProcessing.totalIncome,
              });
              // 月度预算
              MonthlyBudgetCard({
                month: this.vm.dataProcessing.date,
                accountId: this.vm.dataProcessing.currentAccountId,
                totalExpense: Number(this.vm.dataProcessing.totalExpense)
              });
              // 账单列表
              this.billListBuilder();
            }
          }
          .scrollBar(BarState.Off)
          .layoutWeight(1)
          .edgeEffect(EdgeEffect.Spring);
        }
        .width($r('app.string.width_percent_full'))
        .padding({
          left: $r('app.string.space_l'),
          right: $r('app.string.space_l'),
        });
      }
      .layoutWeight(1)
      .onRefreshing(() => {
        this.vm.refreshBill().then(() => {
          this.isRefreshing = false;
        });
      });

      CreateBillButton({
        accountId: this.vm.dataProcessing.currentAccountId,
        handleCreateSuccess: () => {
          EventBus.instance.emit(EventKey.GLOBAL_REFRESH_EVENT);
        },
      });
    }
    .bindSheet($$this.showSheet, this.filterSheetBuilder(), {
      height: this.vm.sheet.sheetHeight,
      preferType: SheetType.CENTER,
      title: { title: this.vm.sheet.title },
    })
    .onAppear(async () => {
      await this.vm.initData();
    })
    .height($r('app.string.height_percent_full'))
    .width($r('app.string.width_percent_full'))
    .backgroundImage($r('app.media.ic_background_home'))
    .backgroundColor($r('app.color.system_color_background_auxiliary'))
    .backgroundImageSize(BreakpointSystem.isTablet ? ImageSize.FILL : ImageSize.Contain)
    .justifyContent(FlexAlign.Start)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
  }

  @Builder
  filterSheetBuilder() {
    if (this.vm.sheet.type === HomeSheetType.DATE) {
      CommonMonthPicker({
        initMonth: this.vm.dataProcessing.date,
        handleConfirm: (dateStr: string) => {
          this.vm.changeMonth(dateStr);
          this.showSheet = false;
        },
        handleCancel: () => {
          this.showSheet = false;
        },
      });
    } else if (this.vm.sheet.type === HomeSheetType.TYPE) {
      TypeFilterSheet({
        initResource: this.vm.checkedResource,
        resource: this.vm.resource,
        handleCancel: () => {
          this.showSheet = false;
        },
        handleConfirm: (type: BalanceChangeType, key: number) => {
          this.vm.changeResource(type, key);
          this.showSheet = false;
        },
      });
    }
  }

  @Builder
  filterBarBuilder() {
    Row() {
      Row() {
        Text(this.vm.dataProcessing.dateLabel)
          .fontColor($r('app.color.font_color_level1'))
          .fontWeight(FontWeight.Medium);
        Image($r('app.media.ic_arrow_bottom'))
          .width(24);
      }
      .onClick(() => {
        this.showSheet = true;
        this.vm.openSheet(HomeSheetType.DATE);
      });

      Row() {
        Text(this.vm.resourceLabel)
          .fontColor($r('app.color.font_color_level1'))
          .fontWeight(FontWeight.Medium);
        Image($r('app.media.ic_arrow_bottom'))
          .width(24);
      }
      .onClick(() => {
        this.vm.openSheet(HomeSheetType.TYPE);
        this.showSheet = true;
      });
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .width($r('app.string.width_percent_full'))
    .height(40)
    .margin({ bottom: $r('app.string.space_m') });
  }

  @Builder
  billListBuilder() {
    List() {
      ForEach(this.vm.dataProcessing.list, (item: DailyBillGroup) => {
        ListItem() {
          BillCard({
            card: item,
            handleDelete: (id: number) => {
              this.vm.deleteBill(id);
            },
            handleClickItem: (bill: BillCardItem) => {
              RouterModule.push({
                url: RouterMap.HOME_BILL_DETAIL,
                param: bill,
                onPop: async () => {
                  this.vm.refreshBill();
                },
              });
            },
          });
        };
      }, (item: DailyBillGroup) => JSON.stringify(item));
      if (!this.vm.dataProcessing.list?.length) {
        // 占位空卡片
        BillCard();
      }
      ListItem() {
        Text('下拉获取最新账单~')
          .fontSize($r('app.string.font_size_12'))
          .fontColor($r('app.color.font_color_level2'))
          .margin({
            top: $r('app.string.space_m'),
            bottom: $r('app.string.space_l'),
          })
          .width($r('app.string.width_percent_full'))
          .textAlign(TextAlign.Center);
      };
    }
    .scrollBar(BarState.Off);
  }
}