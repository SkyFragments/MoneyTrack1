import { AssetSummary, BreakpointSystem, BreakpointTypeEnum  } from 'asset_base';

@ComponentV2
export struct AssetSummaryCard {
  @Param
  cardHeight: Length = 105;
  @Param
  anonymous: boolean = false;
  @Param
  amountTextColor: ResourceColor = '#e6000000';
  @Param
  bgImage: ResourceStr = $r('app.media.ic_bg_summary_card');
  @Param
  assetData: AssetSummary = {
    totalAsset: 0,
    totalLiability: 0,
  };
  @Event
  handleEyeClick: () => void;

  @Computed
  get netAssetLabel() {
    const net = this.assetData.totalAsset + this.assetData.totalLiability;
    return this.anonymous ? '**' : net.toFixed(2);
  }

  @Computed
  get totalAssetLabel() {
    return this.anonymous ? '**' : this.assetData.totalAsset.toFixed(2);
  }

  @Computed
  get totalLiabilityLabel() {
    return this.anonymous ? '**' : this.assetData.totalLiability.toFixed(2);
  }

  build() {
    Column() {
      Row() {
        Text('净资产').labelTextStyle();
        Image(this.anonymous ? $r('app.media.ic_eye_close') : $r('app.media.ic_eye_open'))
          .height(16)
          .width(16)
          .margin({ left: 16 })
          .onClick(() => {
            this.handleEyeClick?.();
          });
      }
      .margin({ bottom: 4 });

      Text(this.netAssetLabel)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.amountTextColor);
      Blank();
      Row() {
        Text() {
          Span('资产');
          Span(' ').letterSpacing(4);
          Span(this.totalAssetLabel)
            .fontColor(this.amountTextColor)
            .fontWeight(FontWeight.Medium)
            .fontSize(14)
        }.labelTextStyle()
        .layoutWeight(1);

        Text() {
          Span('负债');
          Span(' ').letterSpacing(4);
          Span(this.totalLiabilityLabel)
            .fontColor(this.amountTextColor)
            .fontWeight(FontWeight.Medium)
            .fontSize(14)
        }.labelTextStyle()
        .layoutWeight(1);
      };

    }
    .width('100%')
    .height(this.cardHeight)
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .backgroundColor(Color.White)
    .backgroundImage(this.bgImage)
    .borderRadius(16)
    .backgroundImageSize(BreakpointSystem.currentBreakpoint.value === BreakpointTypeEnum.SM
      ? ImageSize.FILL : ImageSize.Contain)
    .backgroundImagePosition(Alignment.TopEnd);
  }
}

@Extend(Text)
function labelTextStyle() {
  .fontSize(12)
  .fontColor('#99000000')
  .fontWeight(FontWeight.Regular);
}