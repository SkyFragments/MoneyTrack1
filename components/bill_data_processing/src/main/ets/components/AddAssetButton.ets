import { Constants } from 'asset_base';
import { AssetManageUtil } from '../utils/AssetManageUtil';
import { emitter } from '@kit.BasicServicesKit';
import { ASSET_CHANGE_EVENT_ID } from '../commons/Constants';
import { WindowUtil } from 'commonlib';

@ComponentV2
export struct AddAssetButton {
  @Event
  handleSuccess: () => void;

  aboutToAppear(): void {
    try {
      emitter.on({ eventId: ASSET_CHANGE_EVENT_ID }, () => {
        this.handleSuccess?.();
      });
    } catch (error) {
      WindowUtil.dealAllError(error);
    }
  }

  aboutToDisappear(): void {
    try {
      emitter.off(ASSET_CHANGE_EVENT_ID);
    } catch (error) {
      WindowUtil.dealAllError(error);
    }
  }

  build() {
    Column() {
      Button() {
        Row() {
          Image($r('app.media.ic_add'))
            .height(16)
            .margin({ right: 8 });
          Text('添加资产')
            .fontColor(Constants.FONT_COLOR_LEVEL1)
            .fontWeight(FontWeight.Medium);
        };
      }
      .width('100%')
      .constraintSize({ maxWidth: 448 })
      .backgroundColor(Constants.BUTTON_BACKGROUND_COLOR_GREY)
      .padding(12)
      .onClick(() => {
        AssetManageUtil.openAddAssetSheet();
      });
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center);
  }
}