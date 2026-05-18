import { CalendarBillSummaryModel } from '../commons/Models';
import { BillCalendar } from '../components/BillCalendar';

@Entry
@ComponentV2
struct BillCalendarExample {
  @Local summary: CalendarBillSummaryModel = new CalendarBillSummaryModel();

  aboutToAppear(): void {
    this.summary.date = '2025-05-15';
    this.summary.totalExpense = 200;
    this.summary.totalIncome = 100;
  }

  build() {
    Column({ space: 16 }) {
      Text('日历视图');
      BillCalendar({
        selectedDateSummary: this.summary,
      });
    }
    .padding(16)
    .backgroundColor('#eee');
  }
}