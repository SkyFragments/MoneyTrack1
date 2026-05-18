import { ToastDialog } from '@hw-agconnect/ui-toast';
import dayjs from 'dayjs';
import { BillConstants } from 'bill_base';
import { CustomKeyboardButtonType } from '../commons/Enums';
import { CustomKeyboardItem } from '../commons/Types';
import { CUSTOM_KEYBOARD_LIST } from '../commons/Constants';
import { BillManageModel } from '../commons/Models';

@ComponentV2
export struct CustomKeyboard {
  @Param
  amountArr: string[] = [''];
  @Param
  initBill: BillManageModel | undefined = undefined;
  @Local
  note: string = '';
  @Local
  date: Date = new Date();
  @Local
  selectedDate: Date = new Date();
  @Local
  showDateDialog: boolean = false;
  @Event
  handleConfirm: (amountArr: string[], note: string, date: Date) => void;
  private _amountScroll: Scroller = new Scroller();

  @Computed
  get displayAmount() {
    return this.amountArr.join('');
  }

  @Computed
  get keyboardH() {
    return 50 * 4 + 16;
  }

  @Computed
  get calendarLabel() {
    const tempLabel = dayjs(this.date).format('YYYY-MM-DD');
    if (tempLabel === dayjs().format('YYYY-MM-DD')) {
      return '今天';
    }
    return dayjs(this.date).format('MM/DD');
  }

  @Monitor('displayAmount')
  handleScroll() {
    if (!this._amountScroll.isAtEnd()) {
      this._amountScroll.scrollEdge(Edge.End);
    }
  }

  aboutToAppear(): void {
    if (this.initBill) {
      this.note = this.initBill.note ?? '';
      this.date = new Date(this.initBill.date);
      this.selectedDate = new Date(this.initBill.date);
    }
  }

  build() {
    Column() {
      this.displayCardBuilder();
      this.keyboardBuilder();
    }.bindSheet($$this.showDateDialog, this.dateDialogBuilder(), {
      height: 380,
      preferType: SheetType.CENTER,
      title: {
        title: '选择日期',
      },
    });
  }

  @Builder
  displayCardBuilder() {
    Column() {
      Scroll(this._amountScroll) {
        Text(this.displayAmount === '' ? '0.00' : this.displayAmount)
          .fontSize(BillConstants.FONT_SIZE_18)
          .fontColor(BillConstants.FONT_COLOR_LEVEL1)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 8 })
          .textAlign(TextAlign.End)
          .maxLines(1);
      }
      .scrollBar(BarState.Off)
      .scrollable(ScrollDirection.Horizontal)
      .scrollSnap({ snapAlign: ScrollSnapAlign.END })
      .align(Alignment.End)
      .width('100%');

      TextInput({ placeholder: '点击添加备注', text: this.note })
        .backgroundColor(BillConstants.BACKGROUND_COLOR_GREY_2)
        .maxLength(100)
        .width('100%')
        .fontSize(BillConstants.FONT_SIZE_16)
        .placeholderFont({ size: BillConstants.FONT_SIZE_16 })
        .fontColor(BillConstants.FONT_COLOR_LEVEL2)
        .padding({
          left: 12,
          right: 12,
          top: 8,
          bottom: 8,
        })
        .onChange((value) => {
          this.note = value;
        });
    }
    .alignItems(HorizontalAlign.Start)
    .padding({
      left: 16,
      right: 16,
      top: 8,
      bottom: 8,
    })
    .backgroundColor(BillConstants.BACKGROUND_COLOR);

  }

  @Builder
  keyboardBuilder() {
    Grid() {
      ForEach(CUSTOM_KEYBOARD_LIST, (item: CustomKeyboardItem) => {
        GridItem() {
          Row() {
            if (item.icon) {
              Image(item.icon).width(16).height(16);
            }
            if (item.text) {
              if (item.type === CustomKeyboardButtonType.CALENDAR) {
                Text(this.calendarLabel)
                  .fontSize(BillConstants.FONT_SIZE_14)
                  .fontColor(BillConstants.FONT_COLOR_LEVEL1)
                  .margin({ left: 2 });
              } else {
                Text(item.text)
                  .fontSize(item.type === CustomKeyboardButtonType.NUMBER ? BillConstants.FONT_SIZE_18 :
                    BillConstants.FONT_SIZE_16)
                  .fontColor(item.fontColor ? item.fontColor : BillConstants.FONT_COLOR_LEVEL1);
              }
            }
          };
        }
        .height(46)
        .borderRadius(BillConstants.BORDER_RADIUS_4)
        .backgroundColor(item.bgColor ? item.bgColor : BillConstants.BACKGROUND_COLOR)
        .onClick(() => {
          this.handleClick(item);
        });
      }, (item: CustomKeyboardItem, index: number) => index + '__' + item.text);
    }
    .height(this.keyboardH)
    .padding(8)
    .columnsTemplate('1fr 1fr 1fr 1fr')
    .rowsGap(4)
    .columnsGap(4)
    .margin({ bottom: 16 });
  }

  @Builder
  dateDialogBuilder() {
    Column() {
      DatePicker({
        start: new Date('1970-1-1'),
        end: new Date(),
        selected: this.date,
      })
        .disappearTextStyle({
          font: { size: BillConstants.FONT_SIZE_14, weight: FontWeight.Regular },
        })
        .textStyle({
          color: BillConstants.FONT_COLOR_LEVEL1,
          font: { size: BillConstants.FONT_SIZE_16, weight: FontWeight.Regular },
        })
        .selectedTextStyle({
          color: BillConstants.FONT_COLOR_LEVEL1,
          font: {
            size: BillConstants.FONT_SIZE_20,
            weight: FontWeight.Medium,
          },
        })

        .onDateChange((value: Date) => {
          this.selectedDate = value;
          console.info('select current date is: ' + value.toString());
        })
        .width('75%');
      Flex() {

        Button('取消')
          .backgroundColor(BillConstants.BACKGROUND_COLOR_GREY_2)
          .fontColor(BillConstants.FONT_COLOR_LEVEL1)
          .onClick(() => {
            this.showDateDialog = false;
          })
          .flexGrow(1);

        Blank().width(16);

        Button('确定')
          .backgroundColor(BillConstants.THEME_COLOR)
          .fontColor(BillConstants.FONT_COLOR_1_INVERT)
          .onClick(() => {
            this.date = this.selectedDate;
            this.showDateDialog = false;
          })
          .flexGrow(1);
      }
      .margin({ top: 24 });
    }
    .padding(16);
  }

  handleClick(btn: CustomKeyboardItem) {
    const len: number = this.amountArr.length;
    let lastAmount: string = this.amountArr[len - 1];
    switch (btn.type) {
      case CustomKeyboardButtonType.NUMBER:
        this.handleClickNumber(btn, len, lastAmount);
        break;
      case CustomKeyboardButtonType.CALENDAR:
        this.showDateDialog = true;
        break;
      case CustomKeyboardButtonType.SUBTRACTION:
        if (lastAmount && !isNaN(Number(lastAmount))) {
          this.amountArr.push(btn.text);
        }
        break;
      case CustomKeyboardButtonType.ADDITION:
        if (lastAmount && !isNaN(Number(lastAmount))) {
          this.amountArr.push(btn.text);
        }
        break;
      case CustomKeyboardButtonType.POINT:
        if (lastAmount && !lastAmount.includes('.')) {
          lastAmount += btn.text;
        }
        this.amountArr.splice(len - 1, 1, lastAmount);
        break;
      case CustomKeyboardButtonType.DELETE:
        if (lastAmount && lastAmount.length > 1) {
          lastAmount = lastAmount.slice(0, lastAmount.length - 1);
          this.amountArr.splice(len - 1, 1, lastAmount);
        } else {
          this.amountArr.pop();
        }
        break;
      case CustomKeyboardButtonType.CONFIRM:
        this.handleConfirm?.(this.amountArr, this.note, this.date);
        break;
      default:
        break;
    }
  }

  handleClickNumber(btn: CustomKeyboardItem, len: number, lastAmount: string) {
    if (lastAmount === '') {
      lastAmount = btn.text;
      this.amountArr.splice(len - 1, 1, lastAmount);
    } else if (isNaN(Number(lastAmount))) {
      this.amountArr.push(btn.text);
    } else if (!(btn.text === '0' && lastAmount === '')) {
      let temp = lastAmount.split('.');
      if (temp.length === 2 && temp[1].length >= 2) {
        ToastDialog.showToast({ message: '最多两位小数~' });
      } else if (temp[0].length >= 6 && !lastAmount.includes('.')) {
        ToastDialog.showToast({ message: '输入金额过大~' });
      } else {
        lastAmount += btn.text;
      }
      this.amountArr.splice(len - 1, 1, lastAmount);
    }
  }
}