import dayjs from 'dayjs';

@ObservedV2
export class CalendarBillItemModel {
  // dayjs时间
  @Trace dayjsObj: dayjs.Dayjs;
  //
  @Trace dateStr: string;
  // 日期
  @Trace day: number;
  // 农历
  @Trace lunarDay: string;
  // 显示颜色
  @Trace lunarColor: ResourceColor;

  constructor(
    dayjsObj: dayjs.Dayjs,
    dateStr: string,
    day: number,
    lunarDay: string,
    lunarColor: ResourceColor,
  ) {
    this.dayjsObj = dayjsObj;
    this.dateStr = dateStr;
    this.day = day;
    this.lunarDay = lunarDay;
    this.lunarColor = lunarColor;
  }
}

@ObservedV2
export class CalendarBillSummaryModel {
  @Trace date: string = '';
  @Trace totalExpense: number = 0;
  @Trace totalIncome: number = 0;
}
