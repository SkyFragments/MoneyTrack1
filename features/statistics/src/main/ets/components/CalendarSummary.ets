import { BillCard } from 'bill_card';
import { BillCalendar } from 'bill_chart';
import { ContainerRow } from 'commonlib';
import { StatisticsVM } from '../viewmodels/StatisticsVM';

@ComponentV2
export struct CalendarSummary {
  @Param vm: StatisticsVM = new StatisticsVM();
  @Local isRefreshing: boolean = false;
  build() {
    Refresh({ refreshing: $$this.isRefreshing }) {
      Scroll() {
        Column() {
          // 日历视图
          this.calendarTableBuilder();
          // 选中日期账单详情
          BillCard({
            card: this.vm.selectedDateData,
          })

          Text('下拉获取最新账单~')
            .fontSize($r('app.string.font_size_12'))
            .fontColor($r('app.color.font_color_level2'))
            .margin({
              top: $r('app.string.space_m'),
              bottom: $r('app.string.space_l'),
            })
            .width($r('app.string.width_percent_full'))
            .textAlign(TextAlign.Center);
        }
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .layoutWeight(1)
    .onRefreshing(() => {
      this.vm.refreshCalendarData().then(() => {
        this.isRefreshing = false;
      });
    });
  }

  @Builder
  calendarTableBuilder() {
    ContainerRow() {
      BillCalendar({
        month:this.vm.dataProcessing.date,
        selectedDateSummary: this.vm.selectedDateSummary,
        startDate: this.vm.dataProcessing.billStartDate,
        endDate: this.vm.dataProcessing.billEndDate,
        handleDateClick: (dateStr: string) => {
          this.vm.getSelectedDateData(dateStr);
        },
      });
    };
  }
}