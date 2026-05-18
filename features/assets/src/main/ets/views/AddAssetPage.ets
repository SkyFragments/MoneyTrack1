import { emitter } from '@kit.BasicServicesKit';
import { ToastDialog } from '@hw-agconnect/ui-toast';
import {
  AssetCategory,
  AssetRecordItemModel,
  AssetDisplayTypeItem,
  AssetType,
  Constants,
  AddAssetParam,
  AssetTypeUtil,
} from 'asset_base';
import { CommonHeader, RouterMap, RouterModule } from 'commonlib';
import { AccountingDB,  ASSET_CHANGE_EVENT_ID } from 'bill_data_processing';

@Builder
export function addAssetPageBuilder() {
  AddAssetPage();
}

@Entry
@ComponentV2
struct AddAssetPage {
  @Local
  assetTypeItem: AssetDisplayTypeItem | undefined = undefined;
  @Local
  type: AssetType = AssetType.FUND;
  @Local
  formData: AssetRecordItemModel = new AssetRecordItemModel();
  @Local
  amount: string = '';

  aboutToAppear(): void {
    const param = RouterModule.getNavParam<AddAssetParam>({
      url: RouterMap.ADD_ASSET,
    });

    if (param) {
      this.type = param.type;
      if (param.subType) {
        const typeItem = AssetTypeUtil.getTypeItem(param.subType);
        this.formData.name = typeItem!.name;
        this.formData.subType = param.subType;
        this.formData.isCustom = false;
      } else {
        this.formData.isCustom = true;
        this.formData.name = '';
      }

      this.formData.type = this.type;
      this.formData.category = this.type === AssetType.FUND ? AssetCategory.ASSET : AssetCategory.LIABILITY;
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部标题栏
        CommonHeader({ title: `添加${ this.formData.name === '' ? '资产' : this.formData.name }` });

        this.assetFormBuilder();

        Blank();

        Column({ space: 8 }) {
          Button('保存')
            .width('100%')
            .backgroundColor(Constants.THEME_COLOR)
            .enabled(typeof this.formData.amount === 'number' || this.amount !== '')
            .onClick(() => {
              this._handleSave();
            });
          Button('取消')
            .width('100%')
            .fontColor($r('sys.color.font_primary'))
            .backgroundColor($r('app.color.system_color_background_grey_level2'))
            .onClick(() => {
              RouterModule.pop();
            });
        }
        .width('100%')
        .constraintSize({ maxWidth: 448 });
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Constants.BACKGROUND_COLOR_GREY);
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.system_color_background_auxiliary'))
    .padding($r('app.string.space_l'));
  }

  @Builder
  assetFormBuilder() {
    Column() {
      // 名称输入
      Row() {
        Text('名称').formLabelStyle();

        if (this.formData.isCustom) {
          TextInput({ text: this.formData.name, placeholder: '请输入名称' })
            .formTextInputStyle()
            .maxLength(10)
            .onChange((value) => {
              this.formData.name = value;
            });
        } else {
          Text(this.formData.name)
            .fontColor(Constants.FONT_COLOR_LEVEL3)
            .fontSize(Constants.FONT_SIZE_14);
        }
      }.formRowStyle();

      Divider().commonDividerStyle();

      // 备注输入
      Row() {
        Text('备注').formLabelStyle();
        TextInput({ text: this.formData.note, placeholder: '选填' })
          .maxLength(24)
          .formTextInputStyle()
          .onChange((value) => {
            this.formData.note = value;
          });
      }.formRowStyle();

      Divider().commonDividerStyle();

      // 金额输入
      Row() {
        Text() {
          Span('金额');
          Span(`(${this.type === AssetType.FUND ? '资产' : '负债'})`);
        }.formLabelStyle();

        TextInput({
          text: this.amount,
          placeholder: this.type === AssetType.FUND ? '请输入' : '如有负债，请填负数',
        })
          .formTextInputStyle()
          .type(InputType.NUMBER_DECIMAL)
          .maxLength(9)
          .onChange((value) => {
            this.amount = value;
          })
          .inputFilter('[-.0-9]');
      }.formRowStyle();
    }
    .backgroundColor(Constants.BACKGROUND_COLOR)
    .borderRadius(Constants.BORDER_RADIUS_16)
    .padding(16)
    .width('100%');
  }

  private async _handleSave() {
    const num = Number(this.amount);
    if (isNaN(num)) {
      ToastDialog.showToast({ message: '请检查输入金额' });
      return;
    }

    if (this.type === AssetType.FUND) {
      if (num < 0) {
        ToastDialog.showToast({ message: '资金账户金额不能为负数' });
        return;
      }
    }

    this.formData.amount = num;

    try {
      await AccountingDB.addAssetAccount({
        name: this.formData.name,
        type: this.formData.type,
        subType: this.formData.subType ?? 999,
        category: this.formData.category,
        amount: this.formData.amount,
        note: this.formData.note ?? '',
      });

      ToastDialog.showToast({ message: '资产账户添加成功~' });
      emitter.emit({ eventId: ASSET_CHANGE_EVENT_ID });
      RouterModule.pop();
    } catch (err) {
      ToastDialog.showToast({ message: '添加失败，请稍后重试' });
      console.error(err);
    }
  }
}


@Extend(Row)
function formRowStyle() {
  .width('100%')
  .justifyContent(FlexAlign.SpaceBetween);
}

@Extend(Text)
function formLabelStyle() {
  .fontColor(Constants.FONT_COLOR_LEVEL1)
  .fontSize(Constants.FONT_SIZE_16)
  .fontWeight(FontWeight.Medium);
}

@Extend(TextInput)
function formTextInputStyle() {
  .padding(2)
  .width('60%')
  .backgroundColor(Constants.BACKGROUND_COLOR)
  .placeholderFont({ size: $r('sys.float.Body_L') })
  .fontSize(Constants.FONT_SIZE_14)
  .caretColor($r('app.color.system_theme_color'))
  .placeholderColor($r('sys.color.font_secondary'))
  .textAlign(TextAlign.End);
}

@Extend(Divider)
function commonDividerStyle() {
  .margin({ top: 12, bottom: 12 });
}
