import { AssetRecordItem, Constants } from 'asset_base';

@ComponentV2
export struct AssetCardItem {
  @Param @Require
  assetItem: AssetRecordItem;
  @Param
  anonymous: boolean = false;
  @Param
  titleSize: Length = Constants.FONT_SIZE_14;
  @Param
  titleColor: ResourceColor = Constants.FONT_COLOR_LEVEL1;
  @Param
  noteSize: Length = Constants.FONT_SIZE_12;
  @Param
  noteColor: ResourceColor = Constants.FONT_COLOR_LEVEL2;
  @Param
  amountColor: ResourceColor = Constants.FONT_COLOR_LEVEL1;
  @Param
  dividerColor: ResourceColor = Constants.DIVIDER_COLOR;
  @Param
  bgColor: ResourceColor = Constants.BACKGROUND_COLOR;

  build() {
    Row() {
      Image(this.assetItem.icon)
        .width(24)
        .borderRadius(12);

      Column() {
        Text(this.assetItem.name)
          .fontSize(this.titleSize)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.titleColor);

        if (this.assetItem.note) {
          Text(this.assetItem.note)
            .fontSize(this.noteSize)
            .fontColor(this.noteColor)
            .maxLines(1)
            .margin({ top: 2 })
            .textOverflow({ overflow: TextOverflow.Ellipsis });
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.SpaceAround)
      .margin({ left: 16, right: 16 });

      Text() {
        if (this.anonymous) {
          Span('**');
        } else {
          Span(this.assetItem.amount >= 0 ? '+' : '');
          Span(this.assetItem.amount.toFixed(2));
        }
      }
      .fontSize(Constants.FONT_SIZE_14)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.amountColor);
    }
    .height(56)
    .backgroundColor(this.bgColor);
  }
}