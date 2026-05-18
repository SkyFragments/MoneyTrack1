import {
  BalanceChangeType,
  DailyBillGroupModel,
  ResourceUtil,
} from 'bill_base';
import {
  BillBarChartData,
  BillBarItem,
  BillPieChartItem,
  CalendarBillSummaryModel,
  ReportTableItem,
} from 'bill_chart';
import { BillProcessingModel } from 'bill_data_processing';
import { EventBus, EventKey, RouterMap, RouterModule } from 'commonlib';
import dayjs from 'dayjs';
import {
  EXPENSE_BAR_HIGHLIGHT_COLOR,
  EXPENSE_BAR_INIT_COLOR,
  EXPENSE_COLOR_LIST,
  INCOME_BAR_HIGHLIGHT_COLOR,
  INCOME_BAR_INIT_COLOR,
  INCOME_COLOR_LIST,
} from '../commons/Constants';
import { SummaryType } from '../commons/Enums';

@ObservedV2
export class StatisticsVM {
  @Trace summaryType: SummaryType = SummaryType.CHART;
  @Trace chartType: BalanceChangeType = BalanceChangeType.EXPENSE;
  @Trace dataProcessing: BillProcessingModel = new BillProcessingModel();
  @Trace selectedDateSummary: CalendarBillSummaryModel =
    new CalendarBillSummaryModel();
  @Trace selectedDateData: DailyBillGroupModel = new DailyBillGroupModel();

  @Computed
  public get summaryLabel() {
    if (this.summaryType === SummaryType.CHART) {
      return '报表';
    }
    return '日历';
  }

  @Computed
  public get pieChartData(): BillPieChartItem[] {
    const map: Map<number, number> = new Map();
    if (this.dataProcessing.bill) {
      this.dataProcessing.bill.transactions.forEach((item) => {
        let preAmount = map.get(item.resource) ?? 0;
        if (item.type === this.chartType) {
          map.set(item.resource, preAmount + item.amount);
        }
      });
      const tempList: (BillPieChartItem | undefined)[] = Array.from(map).map(
        (item) => {
          const resource = ResourceUtil.getResourceItem(item[0]);
          if (!resource) {
            return undefined;
          }
          const pieItem: BillPieChartItem = {
            resource: resource.key,
            label: resource.name,
            value: item[1],
          };
          return pieItem;
        },
      );
      const list = tempList.filter(
        (item) => typeof item !== 'undefined',
      ) as BillPieChartItem[];
      return list;
    }
    return [];
  }

  @Computed
  public get pieChartColor(): number[] {
    if (this.chartType === BalanceChangeType.EXPENSE) {
      return EXPENSE_COLOR_LIST;
    }
    return INCOME_COLOR_LIST;
  }

  @Computed
  public get barChartData(): BillBarChartData {
    const data: BillBarItem[] = [];
    if (this.dataProcessing.list) {
      this.dataProcessing.list.forEach((item) => {
        const amount: number = item.list
          .filter((bill) => bill.type === this.chartType)
          .reduce((pre, bill) => pre + bill.amount, 0);
        const barItem: BillBarItem = {
          date: dayjs(item.list[0].date).format('YYYY-MM-DD'),
          value: amount,
        };
        data.push(barItem);
      });
    }
    return {
      month: this.dataProcessing.date,
      data,
      typeLabel: this.chartType === BalanceChangeType.EXPENSE ? '支出' : '收入',
      startDate: this.dataProcessing.billStartDate,
      endDate: this.dataProcessing.billEndDate,
    };
  }

  @Computed
  public get reportData() {
    const data: ReportTableItem[] = [];
    if (this.dataProcessing.list) {
      this.dataProcessing.list.forEach((item) => {
        const date = item.dateStr;
        const totalIncome = item.list
          .filter((bill) => bill.type === BalanceChangeType.INCOME)
          .reduce((pre, bill) => pre + bill.amount, 0);
        const totalExpense = item.list
          .filter((bill) => bill.type === BalanceChangeType.EXPENSE)
          .reduce((pre, bill) => pre + bill.amount, 0);
        const reportItem: ReportTableItem = {
          date,
          totalIncome,
          totalExpense,
        };
        data.push(reportItem);
      });
    }
    return data;
  }

  @Computed
  public get barInitColor() {
    return this.chartType === BalanceChangeType.EXPENSE
      ? EXPENSE_BAR_INIT_COLOR
      : INCOME_BAR_INIT_COLOR;
  }

  @Computed
  public get barHighlightColor() {
    return this.chartType === BalanceChangeType.EXPENSE
      ? EXPENSE_BAR_HIGHLIGHT_COLOR
      : INCOME_BAR_HIGHLIGHT_COLOR;
  }

  public async initData() {
    await this.dataProcessing.accountProcessing.init();
    await this.dataProcessing.getBillReport();
    this.getSelectedDateData(dayjs().format('YYYY-MM-DD'));
    EventBus.instance.on(EventKey.GLOBAL_REFRESH_EVENT, () => {
      this.refreshCalendarData();
    });
  }

  public async changeChartType(type: BalanceChangeType) {
    this.chartType = type;
  }

  public async changeMonth(dateStr: string) {
    await this.dataProcessing.accountProcessing.loadAccounts();
    this.dataProcessing.changeMonth(dateStr);
    await this.dataProcessing.getBillReport();
    let str: string = '';
    if (dayjs(dateStr).format('YYYY-MM') === dayjs().format('YYYY-MM')) {
      str = dayjs().format('YYYY-MM-DD');
    } else {
      str = dayjs(dateStr).format('YYYY-MM-DD');
    }
    this.getSelectedDateData(str);
  }

  public async refreshCalendarData() {
    await this.dataProcessing.accountProcessing.loadAccounts();
    await this.dataProcessing.getBillReport();
    this.getSelectedDateData(this.selectedDateSummary.date);
  }

  public getSelectedDateData(initStr: string) {
    if (!this.dataProcessing.list) {
      return;
    }
    const dateStr: string = dayjs(initStr).format('YYYY-MM-DD');
    const data = this.dataProcessing.list.find(
      (item) => item.dateStr === dateStr,
    );
    this.selectedDateSummary.date = dateStr;
    this.selectedDateData.dateStr = dateStr;
    if (data?.list) {
      this.selectedDateData.list = data.list;
      const incomeList = data.list.filter(
        (item) => item.type === BalanceChangeType.INCOME,
      );
      this.selectedDateSummary.totalIncome =
        incomeList.reduce((a, item) => a + item.amount, 0) ?? 0;
      const expenseList = data.list.filter(
        (item) => item.type === BalanceChangeType.EXPENSE,
      );
      this.selectedDateSummary.totalExpense =
        expenseList.reduce((a, item) => a + item.amount, 0) ?? 0;
    } else {
      this.selectedDateData.list = [];
      this.selectedDateSummary.totalIncome = 0;
      this.selectedDateSummary.totalExpense = 0;
    }
  }

  public jumpToDetailPage(resource: number) {
    RouterModule.push({
      url: RouterMap.STATISTICS_BILL_BY_RESOURCE,
      param: {
        resource,
        date: this.dataProcessing.date,
      },
    });
  }
}
