import { UIDialog } from '@hw-agconnect/ui-dialog';
import { BreakpointTypeEnum } from 'bill_base';
import { AccountingDB } from 'bill_data_processing';
import { BreakpointSystem, EventBus, EventKey } from 'commonlib';
import dayjs from 'dayjs';
import { BudgetSettingType } from '../commons/Enums';

@ComponentV2
export struct MonthlyBudgetCard {
  @Param month: string = ''; // 格式 YYYY-MM
  @Param accountId: number = 0;
  @Param totalExpense: number = 0;

  @Local budgetAmount: number | null = null;
  @Local showEditSheet: boolean = false;
  @Local inputBudget: string = '';

  aboutToAppear(): void {
    this.loadBudget();
  }

  @Monitor('accountId')
  onAccountIdChange() {
    this.loadBudget();
  }

  @Monitor('month')
  onMonthChange() {
    this.loadBudget();
  }

  async loadBudget() {
    if (this.accountId && this.month) {
      this.budgetAmount = await AccountingDB.getBudget(this.accountId, this.month);
    } else {
      this.budgetAmount = null;
    }
  }

  @Computed
  get monthLabel(): string {
    if (!this.month) {
      return '';
    }
    const date = dayjs(this.month).month() + 1;
    return `${date}月总预算`;
  }

  @Computed
  get remainingBudget(): string {
    if (this.budgetAmount === null) {
      return '--';
    }
    const remaining = this.budgetAmount - this.totalExpense;
    return remaining.toFixed(2);
  }

  @Computed
  get budgetPercent(): number {
    let percent = 0;
    if (this.budgetAmount && this.budgetAmount > 0) {
      const remaining = this.budgetAmount - this.totalExpense;
      percent = (remaining / this.budgetAmount) * 100;
    }
    return Math.max(0, Math.min(100, percent));
  }

  handleMenuAction(action: BudgetSettingType) {
    if (action === BudgetSettingType.EDIT) {
      this.inputBudget = this.budgetAmount ? this.budgetAmount.toString() : '';
      this.showEditSheet = true;
    } else if (action === BudgetSettingType.CLEAR) {
      UIDialog.open({
        contentOptions: {
          content: '清空后将无法恢复，是否清空？',
          contentTextAlign: TextAlign.Center,
        },
        showConfirmButton: true,
        showCancelButton: true,
        confirmButtonOptions: {
          button: '清空',
          buttonFontColor: $r('app.color.icon_color_warning'),
        },
        cancelButtonOptions: {
          buttonFontColor: $r('app.color.font_color_level1'),
        },
        onConfirm: () => this.clearBudget(),
      })
    }
  }

  async saveBudget() {
    const amount = parseFloat(this.inputBudget);
    if (isNaN(amount) || amount < 0) {
      return;
    }
    await AccountingDB.addOrUpdateBudget(this.accountId, this.month, amount);
    this.budgetAmount = amount;
    this.showEditSheet = false;
    EventBus.instance.emit(EventKey.GLOBAL_REFRESH_EVENT);
  }

  async clearBudget() {
    await AccountingDB.deleteBudget(this.accountId, this.month);
    this.budgetAmount = null;
    EventBus.instance.emit(EventKey.GLOBAL_REFRESH_EVENT);
  }

  build() {
    Column() {
      Row() {
        Text(this.monthLabel)
          .fontSize($r('app.string.font_size_16'))
          .fontColor($r('app.color.font_color_level1'))
          .fontWeight(FontWeight.Bold);

        Blank();

        Text('编辑')
          .fontSize($r('app.string.font_size_14'))
          .fontColor($r('app.color.font_color_level1'))
          .bindMenu(this.menuBuilder());
      }
      .width('100%')
      .margin({ bottom: 12 });

      Flex({
        direction: BreakpointSystem.currentBreakpoint.value === BreakpointTypeEnum.SM
        ? FlexDirection.Column : FlexDirection.Row ,
        alignItems: ItemAlign.Center
      }) {
        Column() {
          this.gaugeChart();
        }
        .width(BreakpointSystem.currentBreakpoint.value === BreakpointTypeEnum.SM ? '100%' : '50%')
        .alignItems(HorizontalAlign.Center)

        Column() {
          Row() {
            Text('剩余预算：')
              .fontSize($r('app.string.font_size_16'))
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.font_color_level1'));

            Blank();

            Text(this.remainingBudget)
              .fontSize($r('app.string.font_size_16'))
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.font_color_level1'));
          }
          .width('100%')
          .constraintSize({ maxWidth: 328 })
          .margin({ bottom: 8 });

          Divider()
            .margin({ bottom: 8 });

          Row() {
            Text('本月预算')
              .fontSize($r('app.string.font_size_12'))
              .fontColor($r('app.color.font_color_level2'));

            Blank();

            Text(this.budgetAmount !== null ? this.budgetAmount.toFixed(2) : '--')
              .fontSize($r('app.string.font_size_12'))
              .fontColor($r('app.color.font_color_level2'));
          }
          .width('100%')
          .constraintSize({ maxWidth: 328 })
          .margin({ bottom: 8 });

          Row() {
            Text('本月支出')
              .fontSize($r('app.string.font_size_12'))
              .fontColor($r('app.color.font_color_level2'));

            Blank();

            Text(this.budgetAmount !== null ? this.totalExpense.toFixed(2) : '--')
              .fontSize($r('app.string.font_size_12'))
              .fontColor($r('app.color.font_color_level2'));
          }
          .width('100%')
          .constraintSize({ maxWidth: 328 });
        }
        .width(BreakpointSystem.currentBreakpoint.value === BreakpointTypeEnum.SM ? '100%' : '50%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.system_color_background_white'))
    .borderRadius(16)
    .margin({ bottom: 12 })
    .bindSheet($$this.showEditSheet, this.editSheetBuilder(), {
      height: 280,
      preferType: SheetType.CENTER,
      title: { title: '月度总预算' },
      onDisappear: () => {
        this.inputBudget = '';
      }
    });
  }

  @Builder
  menuBuilder() {
    Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
      Text('编辑月度总预算')
        .fontSize($r('app.string.font_size_16'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.font_color_level1'))
        .width('100%')
        .height(48)
        .textAlign(TextAlign.Center)
        .onClick(() => this.handleMenuAction(BudgetSettingType.EDIT))
      Divider()
      Text('清空月度总预算')
        .fontSize($r('app.string.font_size_16'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.icon_color_warning'))
        .width('100%')
        .height(48)
        .textAlign(TextAlign.Center)
        .onClick(() => this.handleMenuAction(BudgetSettingType.CLEAR))
    }.width(144)
    .padding({ top: 4, bottom: 4, left: 16, right: 16 })
  }

  @Builder
  gaugeChart() {
    Gauge({ value: this.budgetPercent, min: 0, max: 100 }) {
      Column({ space: 4 }) {
        Row({ space: 2 }) {
          Text(this.budgetAmount === null ? '- ' : `${Math.round(this.budgetPercent)}`)
            .fontSize(30)
            .fontColor($r('app.color.font_color_level1'))
            .fontWeight(FontWeight.Bold)
          Text('%')
            .fontSize(14)
            .fontColor($r('app.color.font_color_level1'))
            .fontWeight(FontWeight.Medium)
        }
        Text('剩余')
          .fontSize(12)
          .fontColor($r('app.color.font_color_level2'))
          .fontWeight(FontWeight.Medium)
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .width(140)
    .height(140)
    .startAngle(0)
    .endAngle(360)
    .strokeWidth(16)
    .indicator(null)
    .colors($r('app.color.system_theme_color'))
    .margin({ bottom: 12 })
  }

  @Builder
  editSheetBuilder() {
    Column() {
      // 整数部分最多9位，小数部分最多2位
      TextInput({ placeholder: '请输入总预算', text: this.inputBudget })
        .type(InputType.NUMBER_DECIMAL)
        .caretColor($r('app.color.system_theme_color'))
        .fontSize(18)
        .inputFilter('^-?\\d{0,9}(\\.\\d{0,2})?$')
        .onChange((value: string) => {
          this.inputBudget = value;
        });

      Blank();

      Button('确定')
        .width('100%')
        .height(40)
        .fontSize($r('sys.float.Body_L'))
        .backgroundColor($r('app.color.system_theme_color'))
        .onClick(() => {
          this.saveBudget();
        });
    }
    .width('100%')
    .height('100%')
    .padding(16);
  }
}
