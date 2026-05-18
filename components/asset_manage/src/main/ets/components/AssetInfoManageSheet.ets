import { UIDialog } from '@hw-agconnect/ui-dialog';
import { ToastDialog } from '@hw-agconnect/ui-toast';
import {
  AssetCategory,
  AssetRecordItemModel,
  AssetDisplayTypeItem,
  AssetRecordItem,
  AssetType,
  Constants,
} from 'asset_base';

export interface AssetInfoManageOptions {
  assetTypeItem?: AssetDisplayTypeItem;
  type?: AssetType;
  initAsset?: AssetRecordItem;
  handleConfirm?: (data: AssetRecordItemModel) => void;
  handleEditSuccess?: () => void;
  handleDelete?: (id: number) => void;
}

@Builder
export function assetInfoManageSheetBuilder(options: AssetInfoManageOptions) {
  AssetInfoManageSheet({
    assetTypeItem: options.assetTypeItem,
    type: options.type,
    handleConfirm: options.handleConfirm,
    initAsset: options.initAsset,
    handleEditSuccess: options.handleEditSuccess,
    handleDelete: options.handleDelete,
  });
}

@ComponentV2
export struct AssetInfoManageSheet {
  @Param
  assetTypeItem: AssetDisplayTypeItem | undefined = undefined;
  @Param
  type: AssetType = AssetType.FUND;
  @Param
  initAsset: AssetRecordItem | undefined = undefined;
  @Local
  formData: AssetRecordItemModel = new AssetRecordItemModel();
  @Local
  amount: string = '';
  @Event
  handleConfirm: (data: AssetRecordItemModel) => void;
  @Event
  handleEditSuccess: () => void;
  @Event
  handleDelete: (id: number) => void;

  aboutToAppear(): void {
    this.initData();
  }

  build() {
    Column() {
      this.assetFormBuilder();
      Blank();

      Column() {
        Button('保存')
          .width('100%')
          .backgroundColor(Constants.THEME_COLOR)
          .enabled(typeof this.formData.amount === 'number')
          .onClick(() => {
            const num = Number(this.amount);
            if (typeof num !== 'number') {
              ToastDialog.showToast({ message: '请检查输入金额' });
              return;
            }
            this.formData.amount = num;
            this.handleConfirm?.(this.formData);
          });
        if (this.initAsset?.assetId) {
          Button('删除')
            .width('100%')
            .backgroundColor(Constants.BUTTON_BACKGROUND_COLOR_GREY)
            .fontColor(Constants.WARNING_COLOR)
            .enabled(this.formData.amount !== 0)
            .margin({ top: 16 })
            .onClick(() => {
              UIDialog.open({
                contentOptions: {
                  content: '删除资产账户会取消所有该账户名下的记账数据关联，并且无法恢复关联。请确认是否删除？',
                  contentTextAlign: TextAlign.Center,
                },
                showConfirmButton: true,
                showCancelButton: true,
                confirmButtonOptions: {
                  button: '删除',
                  buttonFontColor: Constants.WARNING_COLOR,
                },
                cancelButtonOptions: {
                  button: '取消',
                  buttonFontColor:  Constants.FONT_COLOR_LEVEL1,
                },
                onConfirm: () => {
                  this.handleDelete?.(this.initAsset!.assetId);
                  UIDialog.closeLast();
                }
              })
            });
        }
      }
      .margin({ bottom: 16 })
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor(Constants.BACKGROUND_COLOR_GREY);
  }

  @Builder
  assetFormBuilder() {
    Column() {
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

  initData() {
    if (this.initAsset) {
      this.formData.assetId = this.initAsset.assetId;
      this.formData.name = this.initAsset.name;
      this.formData.type = this.initAsset.type;
      this.formData.subType = this.initAsset.subType;
      this.formData.category = this.initAsset.category;
      this.formData.note = this.initAsset.note ?? '';
      this.formData.amount = this.initAsset.amount;
      this.formData.isCustom = this.initAsset.isCustom ?? false;
      this.amount = this.initAsset.amount.toString();
      return;
    }
    if (!this.assetTypeItem) {
      this.formData.isCustom = true;
    } else {
      this.formData.name = this.assetTypeItem.name;
      this.formData.subType = this.assetTypeItem.subType;
    }
    this.formData.type = this.type;
    this.formData.category = this.type === AssetType.FUND ? AssetCategory.ASSET : AssetCategory.LIABILITY;
    this.amount = '';
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
  .margin(0)
  .padding(2)
  .width('60%')
  .backgroundColor(Constants.BACKGROUND_COLOR)
  .placeholderFont({ size: Constants.FONT_SIZE_14 })
  .fontSize(Constants.FONT_SIZE_14)
  .placeholderColor(Constants.FONT_COLOR_LEVEL2)
  .textAlign(TextAlign.End);

}

@Extend(Divider)
function commonDividerStyle() {
  .margin({
    top: 12,
    bottom: 12,
  });
}