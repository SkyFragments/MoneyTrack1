import { CapsuleSegmentButtonV2, LengthUnit, SegmentButtonV2Items, ColorMetrics } from '@kit.ArkUI';
import { AssetChangeType, TimeRangeType } from 'asset_base';
import { CommonHeader, ContainerColumn } from 'commonlib';
import { BillPieChart } from 'bill_chart';
import { AssetAnalysisVM } from '../viewmodels/AssetAnalysisVM';
import { BalanceTypeSelection } from '../components/BalanceTypeSelection';
import { AssetFilterSheet } from '../components/AssetFilterSheet';
import { AssetLineChart } from '../components/AssetLineChart';

@Builder
export function assetAnalysisPageBuilder() {
  AssetAnalysisPage();
}

@ComponentV2
struct AssetAnalysisPage {
  vm: AssetAnalysisVM = new AssetAnalysisVM();

  @Local showFilterSheet: boolean = false;

  // 资产筛选弹窗中当前的临时选择
  @Local filterSelectedAssetIds: Set<number> = new Set();

  @Local timeRangeItems: SegmentButtonV2Items = new SegmentButtonV2Items([
    { text: '年' },
    { text: '月' },
  ]);
  @Local selectedIndex: number = 1;

  aboutToAppear(): void {
    this.vm.initData();
    this.filterSelectedAssetIds = new Set(this.vm.selectedAssetIds);
  }

  build() {
    NavDestination() {
      Column() {
        CommonHeader({ title: '资产分析' });

        Scroll() {
          Column() {
            // 资产占比饼图
            ContainerColumn() {
              BalanceTypeSelection({
                netAssetLabel: '净资产占比',
                liabilityLabel: '负债占比',
                curType: this.vm.curType,
                changeType: (type: AssetChangeType) => {
                  this.vm.changeType(type);
                },
              }).margin({ bottom: 12 });

              BillPieChart({
                chartData: this.vm.pieChartData,
                colorList: this.vm.chartColors,
                showCenterText: true,
                centerText: this.vm.centerText,
                holeRadius: 80,
                chartHeight: 220
              })
            };

            // 资产变化折线图区域
            ContainerColumn() {
              // 标题行
              Row() {
                Text('资产变化')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor($r('app.color.font_color_level1'))
                  .layoutWeight(1);
                // 筛选按钮
                Row() {
                  Text('筛选')
                    .fontSize(14)
                    .fontColor($r('app.color.font_color_level1'));
                  Image($r('app.media.ic_asset_filter'))
                    .width(16)
                    .height(16)
                    .margin({ left: 2 })
                }
                .onClick(() => {
                  this.filterSelectedAssetIds = new Set(this.vm.selectedAssetIds);
                  this.showFilterSheet = true;
                });
              }
              .width('100%')
              .margin({ bottom: 16 });

              // 时间切换
              Row() {
                CapsuleSegmentButtonV2({
                  items: this.timeRangeItems,
                  selectedIndex: this.selectedIndex,
                  $selectedIndex: (index: number) => {
                    if (index === 1) {
                      this.selectedIndex = 1;
                      this.vm.changeTimeRangeType(TimeRangeType.MONTH);
                    } else {
                      this.selectedIndex = 0;
                      this.vm.changeTimeRangeType(TimeRangeType.YEAR);
                    }
                  },
                  buttonMinHeight: {
                    value: 28,
                    unit: LengthUnit.VP,
                  },
                  itemSelectedBackgroundColor: ColorMetrics.rgba(148, 185, 130, 1),
                })
                  .width(120)
                  .height(28)
              }
              .width('100%')
              .justifyContent(FlexAlign.End)

              // 使用折线图组件，传入数据
              AssetLineChart({
                trendData: this.vm.trendData,
                timeRangeType: this.vm.timeRangeType,
                chartHeight: 200
              })
            }
          }
          .width('100%');
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off);
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.system_color_background_auxiliary'))
    .padding($r('app.string.space_l'))
    .bindSheet($$this.showFilterSheet, this.filterSheetBuilder(), {
      height: 500,
      preferType: SheetType.BOTTOM,
      title: this.sheetTitleBuilder(),
      showClose: false,
      onDisappear: () => {
        // 弹窗关闭时重新加载趋势数据
        this.vm.loadTrendData();
      }
    });
  }

  @Builder
  sheetTitleBuilder() {
    Row() {
      Image($r('app.media.ic_asset_close'))
        .width(40)
        .margin({ right: 8 })
        .onClick(() => {
          this.showFilterSheet = false;
        })

      Text('选择账户')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)

      Image($r('app.media.ic_asset_confirm'))
        .width(40)
        .onClick(() => {
          this.vm.updateSelectedAssets(new Set(this.filterSelectedAssetIds));
          this.showFilterSheet = false;
        })
    }
    .width('100%')
  }

  @Builder
  filterSheetBuilder() {
    AssetFilterSheet({
      currentSelection: this.vm.selectedAssetIds,
      assetGroup: this.vm.assetProcessing.assetGroup,
      selectionChange: (selectedIds: Set<number>) => {
        this.filterSelectedAssetIds = new Set(selectedIds);
      }
    });
  }
}
