import { CommonHeader, CommonMonthPicker } from 'commonlib';
import { SummaryType } from '../commons/Enums';
import { CalendarSummary } from '../components/CalendarSummary';
import { ChartSummary } from '../components/ChartSummary';
import { StatisticsVM } from '../viewmodels/StatisticsVM';

@ComponentV2
export struct StatisticsView {
  vm: StatisticsVM = new StatisticsVM();
  @Local showDateSheet: boolean = false;

  build() {
    Column() {
      CommonHeader({ title: '统计' });
      Column() {
        // 数据过滤栏
        this.filterBarBuilder();
        // 收支概况
        if (this.vm.summaryType === SummaryType.CHART) {
          ChartSummary({
            vm: this.vm,
          });
        } else {
          CalendarSummary({
            vm: this.vm,
          });
        }
      }
      .padding({
        left: $r('app.string.space_l'),
        right: $r('app.string.space_l'),
      })
      .layoutWeight(1)
      .bindSheet($$this.showDateSheet, this.monthSheetBuilder(), {
        height: 360,
        preferType: SheetType.BOTTOM,
        title: { title: '选择月份' },
      });

    }
    .onAppear(() => {
      this.vm.initData();
    })
    .width($r('app.string.width_percent_full'))
    .layoutWeight(1)
    .backgroundColor($r('app.color.system_color_background_auxiliary'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
  }

  @Builder
  filterBarBuilder() {
    Row() {
      Row() {
        Text(this.vm.dataProcessing.dateLabel).filterTextStyle();
        Image($r('app.media.ic_arrow_bottom'))
          .width(28)
          .onClick(() => {
            this.showDateSheet = true;
          });
      };

      Select([
        { value: '报表' },
        { value: '日历' }])
        .font({ size: 16, weight: 500 })
        .fontColor($r('app.color.font_color_level1'))
        .backgroundColor(Color.Transparent)
        .selected(this.vm.summaryType === SummaryType.CHART ? 0 : 1)
        .value(this.vm.summaryLabel)
        .selectedOptionFont({ size: 16, weight: 400 })
        .selectedOptionFontColor($r('app.color.font_color_level1'))
        .selectedOptionBgColor($r('app.color.button_color_background'))
        .optionFont({ size: 16, weight: 400 })
        .optionWidth(100)
        .margin(0)
        .padding(0)
        .height(28)
        .onSelect((index: number) => {
          this.vm.summaryType = index === 0 ? SummaryType.CHART : SummaryType.CALENDAR;
        });
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .width($r('app.string.width_percent_full'))
    .margin({ bottom: $r('app.string.space_m') });
  }

  @Builder
  monthSheetBuilder() {
    CommonMonthPicker({
      initMonth: this.vm.dataProcessing.date,
      handleConfirm: (dateStr: string) => {
        this.vm.changeMonth(dateStr);
        this.showDateSheet = false;
      },
      handleCancel: () => {
        this.showDateSheet = false;
      },
    });
  }
}

@Extend(Text)
function filterTextStyle() {
  .fontColor($r('app.color.font_color_level1'))
  .fontWeight(FontWeight.Medium)
  .fontSize($r('app.string.font_size_16'));
}
