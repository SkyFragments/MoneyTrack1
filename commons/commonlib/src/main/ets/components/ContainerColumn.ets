@ComponentV2
export struct ContainerColumn {
  @Param title: string = '';
  @Param subTitle: string = '';
  @Param bottomGap: boolean = true;
  @Param alignStyle: HorizontalAlign = HorizontalAlign.Start;
  @BuilderParam customBuilderParam: () => void;

  build() {
    Column() {
      if (this.title) {
        Row() {
          Text(this.title).titleStyle();
          Text(this.subTitle).subTitleStyle();
        }
        .justifyContent(FlexAlign.Start)
        .width($r('app.string.width_percent_full'));
      }

      this.customBuilderParam();
    }
    .alignItems(this.alignStyle)
    .margin({ bottom: this.bottomGap ? $r('app.string.space_m') : 0 })
    .backgroundColor($r('app.color.system_color_background_white'))
    .borderRadius($r('app.string.border_radius_l'))
    .width($r('app.string.width_percent_full'))
    .padding($r('app.string.space_m'))
    .height('auto')
  }
}

@Extend(Text)
function titleStyle() {
  .fontSize($r('app.string.font_size_16'))
  .fontWeight(FontWeight.Medium)
  .layoutWeight(1)
  .fontColor($r('app.color.font_color_level1'));
}

@Extend(Text)
function subTitleStyle() {
  .fontSize($r('app.string.font_size_12'))
  .fontColor($r('app.color.font_color_level2'));
}