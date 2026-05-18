@ComponentV2
export struct CommonDivider {
  @Param color: ResourceColor = $r('app.color.system_color_background_grey_level1');
  @Param strokeWidth: string | number = 1;
  @Param gap: Length = $r('app.string.space_m');
  @Param vertical: boolean = false;

  build() {
    Divider()
      .vertical(this.vertical)
      .color(this.color)
      .strokeWidth(this.strokeWidth)
      .lineCap(LineCapStyle.Butt)
      .margin({
        top: this.vertical ? 0 : this.gap,
        bottom: this.vertical ? 0 : this.gap,
        left: this.vertical ? this.gap : 0,
        right: this.vertical ? this.gap : 0,
      });
  }
}