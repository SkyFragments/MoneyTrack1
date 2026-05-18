import { BillBarChart, BillPieChart, BillRanking, BillReportTable } from 'bill_chart';
import { BillSummaryCard } from 'bill_card';
import { BreakpointSystem, BreakpointTypeEnum, ContainerColumn } from 'commonlib';
import { StatisticsVM } from '../viewmodels/StatisticsVM';
import { BalanceTypeSelection } from './BalanceTypeSelection';

@ComponentV2
export struct ChartSummary {
  @Param vm: StatisticsVM = new StatisticsVM();

  build() {
    Scroll() {
      Column() {
        // 月度统计概览
        BillSummaryCard({
          totalExpense: this.vm.dataProcessing.totalExpense,
          totalIncome: this.vm.dataProcessing.totalIncome,
        });
        // 饼图
        this.pieChartBuilder();
        // 柱状图
        this.barChartBuilder();
        // 逐日报表
        this.reportBuilder();
      };
    }
    .scrollBar(BarState.Off)
    .layoutWeight(1)
    .edgeEffect(EdgeEffect.Spring);
  }

  @Builder
  pieChartBuilder() {
    ContainerColumn() {
      BalanceTypeSelection({
        expenseLabel: '支出占比',
        incomeLabel: '收入占比',
        curType: this.vm.chartType,
        changeType: (type) => {
          this.vm.changeChartType(type);
        },
      });
      Flex({
        direction: (BreakpointSystem.currentBreakpoint.value === BreakpointTypeEnum.SM || !this.vm.pieChartData.length)
          ? FlexDirection.Column : FlexDirection.Row,
        alignItems: ItemAlign.Center,
      }) {
        BillPieChart({
          chartData: this.vm.pieChartData,
          colorList: this.vm.pieChartColor,
        }).width((BreakpointSystem.currentBreakpoint.value === BreakpointTypeEnum.SM || !this.vm.pieChartData.length)
          ? '100%' : '50%');
        BillRanking({
          chartData: this.vm.pieChartData,
          colorList: this.vm.pieChartColor,
          handleClickBar: (resource: number) => {
            this.vm.jumpToDetailPage(resource);
          },
        }).width(BreakpointSystem.currentBreakpoint.value === BreakpointTypeEnum.SM ? '100%' : '50%');
      }
    };
  }

  @Builder
  barChartBuilder() {
    ContainerColumn() {
      BalanceTypeSelection({
        expenseLabel: '支出统计',
        incomeLabel: '收入统计',
        curType: this.vm.chartType,
        changeType: (type) => {
          this.vm.changeChartType(type);
        },
      })
        .margin({bottom:$r('app.string.space_m')})

      BillBarChart({
        chartData: this.vm.barChartData,
        initColor: this.vm.barInitColor,
        highlightColor: this.vm.barHighlightColor,
      })
        .margin({bottom:$r('app.string.space_m')})
    };
  }

  @Builder
  reportBuilder() {
    ContainerColumn() {
      Row() {
        Text('报表统计')
          .fontSize($r('app.string.font_size_18'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.font_color_level1'));
      }
      .margin({ bottom: $r('app.string.space_l') })
      .width($r('app.string.width_percent_full'))
      .justifyContent(FlexAlign.SpaceBetween);

      BillReportTable({
        tableData: this.vm.reportData,
      });
    };
  }
}