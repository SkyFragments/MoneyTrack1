import { AssetChangeType } from 'asset_base';

@ComponentV2
export struct BalanceTypeSelection {
  @Param
  netAssetLabel: string = '净资产';
  @Param
  liabilityLabel: string = '负债';
  @Param
  curType: AssetChangeType = AssetChangeType.NET_ASSET;
  @Event
  changeType: (type: AssetChangeType) => void;

  build() {
    Row() {
      Text(this.netAssetLabel)
        .labelStyle(this.curType === AssetChangeType.NET_ASSET)
        .onClick(() => {
          this.changeType?.(AssetChangeType.NET_ASSET);
        });
      Text(this.liabilityLabel)
        .labelStyle(this.curType === AssetChangeType.LIABILITY)
        .onClick(() => {
          this.changeType?.(AssetChangeType.LIABILITY);
        });
    }
    .width($r('app.string.width_percent_full'))
    .height(40)
    .padding(2)
    .borderRadius($r('app.string.border_radius_capsule'))
    .backgroundColor($r('app.color.system_color_background_grey_level2'));
  }
}

@Extend(Text)
function labelStyle(isChecked: boolean) {
  .fontColor($r('app.color.font_color_level1'))
  .fontSize($r('app.string.font_size_14'))
  .fontWeight(FontWeight.Medium)
  .textAlign(TextAlign.Center)
  .width($r('app.string.width_percent_half'))
  .height($r('app.string.height_percent_full'))
  .borderRadius($r('app.string.border_radius_capsule'))
  .backgroundColor(isChecked ? $r('app.color.system_color_background_white') : Color.Transparent);
}