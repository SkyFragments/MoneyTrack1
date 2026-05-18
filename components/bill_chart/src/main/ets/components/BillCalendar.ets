import { Lunar } from 'lunar';
import dayjs from 'dayjs';
import { Constants } from '../commons/Constants';
import { CalendarBillItemModel, CalendarBillSummaryModel } from '../commons/Models';

@ComponentV2
export struct BillCalendar {
  @Param
  month: string = dayjs().format('YYYY-MM');
  @Param
  selectedDateSummary: CalendarBillSummaryModel = new CalendarBillSummaryModel();
  @Param
  calendarHeight: Length = 360;
  @Param
  bgColor: ResourceColor = Color.White;
  @Param
  startDate: string = '';
  @Param
  endDate: string = '';
  @Local
  dateList: CalendarBillItemModel[] = [];
  @Event
  handleDateClick: (dateStr: string) => void;

  @Monitor('month')
  handleDateChange() {
    this.getDateList();
  }

  aboutToAppear(): void {
    this.getDateList();
  }

  private isDateInRange(dateStr: string): boolean {
    if (!this.startDate || !this.endDate) {
      return true;
    }
    const date = dayjs(dateStr);
    const start = dayjs(this.startDate);
    const end = dayjs(this.endDate);
    return date.isSame(start) || date.isSame(end) || (date.isAfter(start) && date.isBefore(end));
  }

  build() {
    Column() {
      this.weekLabelBuilder();
      this.weekGridBuilder();
    }
    .backgroundColor(this.bgColor);
  }

  @Builder
  weekLabelBuilder() {
    Row() {
      ForEach(Constants.WEEK_LABEL_LIST, (item: string) => {
        Text(item)
          .fontSize(12)
          .fontColor(item === '日' || item === '六' ? Constants.FONT_COLOR_LEVEL3 : Constants.FONT_COLOR_LEVEL1)
          .textAlign(TextAlign.Center);
      }, (item: string) => item);
    }
    .width('100%')
    .margin({ bottom: 16 })
    .justifyContent(FlexAlign.SpaceAround);
  }

  @Builder
  weekGridBuilder() {
    Grid() {
      ForEach(this.dateList, (item: CalendarBillItemModel) => {
        GridItem() {
          if (this.selectedDateSummary.date !== item.dateStr) {
            Column() {
              Text(item.day?.toString() ?? '')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.isDateInRange(item.dateStr) ?
                  Constants.FONT_COLOR_LEVEL1 : Constants.FONT_COLOR_LEVEL3);
              Text(item.lunarDay)
                .fontSize(10)
                .fontWeight(FontWeight.Regular)
                .fontColor(item.lunarColor);
            }
            .justifyContent(FlexAlign.Start)
            .padding({
              top: 4,
              left: 2,
              right: 2,
              bottom: 4,
            })
            .width('100%')
            .height('100%');
          } else {
            Column() {
              Text(item.day?.toString() ?? '')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(Constants.FONT_COLOR_1_INVERT)
                .margin({ bottom: 2 });
              Text('+' + this.selectedDateSummary.totalIncome.toFixed(2))
                .selectedDateSummaryStyle();
              Text('-' + this.selectedDateSummary.totalExpense.toFixed(2))
                .selectedDateSummaryStyle();
            }
            .backgroundColor(Constants.THEME_COLOR)
            .borderRadius(8)
            .padding({
              top: 4,
              left: 2,
              right: 2,
              bottom: 4,
            })
            .justifyContent(FlexAlign.Start)
            .width('100%')
            .height('100%');
          }
        }
        .padding(4)
        .onClick(() => {
          if (this.isDateInRange(item.dateStr)) {
            this.handleDateClick?.(item.dateStr);
          }
        });
      }, (item: CalendarBillItemModel, index: number) => index + '__' + item.dateStr);
    }
    .height(this.calendarHeight)
    .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
    .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr')
    .columnsGap(0)
    .rowsGap(4);
  }

  getDateList() {
    let dateList: CalendarBillItemModel[] = [];
    let startDay = this.startDate ? dayjs(this.startDate) : dayjs(this.month).startOf('month');
    let gridStartDay = startDay.startOf('week');
    for (let i = 0; i < 42; i++) {
      let dayjsObj = gridStartDay.add(i, 'day');
      let day = dayjsObj.date();
      let lunarDay = '';
      let lunarColor = Constants.FONT_COLOR_LEVEL1;
      let lunarDate = Lunar.fromDate(dayjsObj.toDate());
      if (lunarDate.getFestivals().length !== 0) { // 显示节日
        lunarDay = lunarDate.getFestivals()[0];
        lunarColor = Constants.THEME_COLOR;
      } else if (lunarDate.getJieQi() !== '') { // 显示节气
        lunarDay = lunarDate.getJieQi();
        lunarColor = Constants.THEME_COLOR;
      } else { // 显示农历日期
        lunarDay = lunarDate.getDayInChinese();
      }

      dateList.push(new CalendarBillItemModel(
        dayjsObj,
        dayjsObj.format('YYYY-MM-DD'),
        day,
        lunarDay,
        lunarColor
      ));
    }
    this.dateList = dateList;
  }
}

@Extend(Text)
function selectedDateSummaryStyle() {
  .fontSize(10)
  .fontColor(Constants.FONT_COLOR_1_INVERT)
  .maxLines(1)
  .textOverflow({ overflow: TextOverflow.Ellipsis });
}