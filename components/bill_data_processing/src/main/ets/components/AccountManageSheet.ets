import { UIDialog } from '@hw-agconnect/ui-dialog';
import { ToastDialog } from '@hw-agconnect/ui-toast';
import { Constants } from 'asset_base';
import { AccountType } from 'bill_base';
import { CommonDayPicker } from 'commonlib';
import { AccountFormModel } from '../models/AccountFormModel';
import { AccountTableBasis } from '../utils/accountingdb/Types';

export interface AccountInfoManageOptions {
  initAccount?: AccountTableBasis;
  handleConfirm: (data: AccountTableBasis) => void;
}

@Builder
export function accountInfoManageSheetBuilder(options: AccountInfoManageOptions) {
  AccountInfoManageSheet({
    initAccount: options.initAccount,
    handleConfirm: options.handleConfirm,
  });
}

@ComponentV2
export struct AccountInfoManageSheet {
  @Param
  initAccount: AccountTableBasis | undefined = undefined;
  @Event
  handleConfirm: (data: AccountTableBasis) => void;

  @Local
  formData: AccountFormModel = new AccountFormModel();

  aboutToAppear(): void {
    this.initData();
  }

  build() {
    Column() {
      this.accountFormBuilder();
      Blank();

      Button('保存')
        .width('100%')
        .backgroundColor(Constants.THEME_COLOR)
        .margin({ bottom: 16 })
        .onClick(() => {
          if (!this.validate()) {
            return;
          }
          this.handleConfirm?.(this.formData.toAccountTableBasis());
        });
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor(Constants.BACKGROUND_COLOR_GREY)
  }

  @Builder
  accountFormBuilder() {
    Column({ space: 12 }) {
      // 账本名称
      Column() {
        TextInput({ text: this.formData.name, placeholder: '请输入账本名称' })
          .formTextInputStyle()
          .maxLength(10)
          .showCounter(true)
          .onChange((value) => {
            this.formData.name = value;
          });
      }
      .width('100%')
      .padding({ top: 2, bottom: 2 })
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .borderRadius($r('app.string.border_radius_s'))

      // 每月账单统计日
      Row() {
        Column({ space: 2 }) {
          Text('每月开始日')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.font_color_level1'))
            .textAlign(TextAlign.Start)
          Text('每月账单统计开始日')
            .fontSize(12)
            .fontColor($r('app.color.font_color_level2'))
            .textAlign(TextAlign.Start)
        }.alignItems(HorizontalAlign.Start)
        Row({ space: 4 }) {
          Text(`${this.formData.date}日`)
            .fontColor(Constants.FONT_COLOR_LEVEL1)
            .fontSize(Constants.FONT_SIZE_14)
          Image($r('app.media.ic_arrow_right_small'))
            .width(12)
            .height(24)
            .onClick(() => {
              UIDialog.open({
                contentBuilder: () => this.dayPickerDialog()
              })
            });
        }
      }.formRowStyle();

      // 是否设置为默认账本
      Row() {
        Text('设置为默认账本').formLabelStyle();
        Toggle({ type: ToggleType.Switch, isOn: this.formData.type === AccountType.DEFAULT })
          .selectedColor($r('app.color.system_theme_color'))
          .onChange((isOn: boolean) => {
            this.formData.type = isOn ? AccountType.DEFAULT : AccountType.CUSTOM;
          });
      }.formRowStyle();
    }
    .width('100%');
  }

  @Builder
  dayPickerDialog() {
    CommonDayPicker({
      initDay: this.formData.date,
      handleConfirm: (dayStr: string) => {
        this.formData.date = dayStr.padStart(2, '0');
        UIDialog.closeLast();
      },
      handleCancel: () => {
        UIDialog.closeLast();
      }
    })
  }

  initData() {
    if (this.initAccount) {
      this.formData.init(this.initAccount);
    } else {
      this.formData.accountId = new Date().getTime();
      this.formData.name = '';
      this.formData.type = AccountType.CUSTOM;
      this.formData.date = '01';
      this.formData.accountIncome = 0;
      this.formData.accountExpense = 0;
    }
  }

  validate(): boolean {
    if (!this.formData.name || this.formData.name.trim().length === 0) {
      ToastDialog.showToast({ message: '请输入账本名称' });
      return false;
    }
    if (this.formData.name.length > 10) {
      ToastDialog.showToast({ message: '账本名称不能超过10个字' });
      return false;
    }
    return true;
  }
}

@Extend(Row)
function formRowStyle() {
  .width('100%')
  .padding({ left: 12, right: 12, top: 8, bottom: 8 })
  .backgroundColor($r('sys.color.comp_background_list_card'))
  .borderRadius($r('app.string.border_radius_s'))
  .justifyContent(FlexAlign.SpaceBetween)
  .alignItems(VerticalAlign.Center);
}

@Extend(Text)
function formLabelStyle() {
  .fontColor(Constants.FONT_COLOR_LEVEL1)
  .fontSize(Constants.FONT_SIZE_16)
  .fontWeight(FontWeight.Medium);
}

@Extend(TextInput)
function formTextInputStyle() {
  .width('100%')
  .backgroundColor(Constants.BACKGROUND_COLOR)
  .caretColor($r('app.color.system_theme_color'))
  .placeholderFont({ size: $r('sys.float.Body_L') })
  .fontSize(Constants.FONT_SIZE_14)
  .placeholderColor($r('sys.color.font_secondary'))
  .textAlign(TextAlign.Start);
}