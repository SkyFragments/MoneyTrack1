import {
  MOCK_PIE_CHART_LIST,
  MOCK_PIE_CHART_LIST2,
  MOCK_BAR_CHART_LIST,
  MOCK_BAR_CHART_LIST2,
  MOCK_COLOR_LIST,
  MOCK_COLOR_LIST2,
  MOCK_TABLE_DATA,
} from './Mockdata';
import { BillPieChart } from '../components/BillPieChart';
import { BillRanking } from '../components/BillRanking';
import { BillBarChart } from '../components/BillBarChart';
import { BillReportTable } from '../components/BillReportTable';
import { BillCalendar } from '../components/BillCalendar';
import { BillBarChartData } from '../commons/Types';
import { CalendarBillSummaryModel } from '../commons/Models';

@Entry
@ComponentV2
struct PreviewPage {
  @Local showChart: boolean = true;
  @Local isExpense: boolean = true;
  @Local summary: CalendarBillSummaryModel = new CalendarBillSummaryModel();

  @Computed
  get barData(): BillBarChartData {
    const list = this.isExpense ? MOCK_BAR_CHART_LIST : MOCK_BAR_CHART_LIST2;
    return {
      month: '2025-05',
      data: list,
      startDate: '',
      endDate: ''
    };
  }

  @Computed
  get barColor() {
    return this.isExpense ? 0x8094b982 : 0x80f2992c;
  }

  @Computed
  get colorList() {
    return this.isExpense ? MOCK_COLOR_LIST : MOCK_COLOR_LIST2;
  }

  @Computed
  get pieData() {
    return this.isExpense ? MOCK_PIE_CHART_LIST : MOCK_PIE_CHART_LIST2;
  }

  build() {
    Column({ space: 16 }) {
      Row() {
        Text(this.showChart ? '图表' : '日历').fontSize(18).fontWeight(FontWeight.Medium);
        Button('切换展示')
          .onClick(() => {
            this.showChart = !this.showChart;
          });
      }.width('100%').justifyContent(FlexAlign.SpaceBetween);

      if (this.showChart) {
        Row() {
          Radio({ value: 'Radio1', group: 'radioGroup' }).checked(true)
            .onChange((isChecked: boolean) => {
              this.isExpense = isChecked;
            });
          Text('支出');
          Blank().width(30);
          Radio({ value: 'Radio2', group: 'radioGroup' }).checked(false)
            .onChange((isChecked: boolean) => {
              this.isExpense = !isChecked;
            });
          Text('收入');
        };

        Scroll() {
          Column({ space: 16 }) {
            // 饼图
            BillPieChart({
              chartData: this.pieData,
              colorList: this.colorList,
            });
            // 账单列表图
            BillRanking({
              chartData: this.pieData,
              colorList: this.colorList,
            });
            //柱状图
            BillBarChart({
              chartData: this.barData,
              initColor: this.barColor,
            });
            // 报表
            BillReportTable({
              tableData: MOCK_TABLE_DATA,
            });
          };

        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      } else {
        // 日历视图
        BillCalendar({
          selectedDateSummary: this.summary,
          handleDateClick: (date) => {
            this.summary.date = date;
          },
        });
      }
    }
    .padding(16);
  }
}