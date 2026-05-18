import { ContainerColumn } from 'commonlib';

@ComponentV2
export struct BillInfoCard {
  @Param
  totalDays: number = 0;
  @Param
  totalBills: number = 0;

  build() {
    ContainerColumn({ bottomGap: false }) {
      Row() {
        // 记账天数
        Column({ space: 4 }) {
          Text(this.totalDays.toString())
            .fontSize(20)
            .fontColor($r('app.color.font_color_level1'))
            .fontWeight(FontWeight.Medium);
          Text('记账总天数')
            .fontSize(12)
            .fontColor($r('app.color.font_color_level2'));
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center);

        Divider().vertical(true).height(32).color($r('app.color.divider_color'));

        // 记账笔数
        Column({ space: 4 }) {
          Text(this.totalBills.toString())
            .fontSize(20)
            .fontColor($r('app.color.font_color_level1'))
            .fontWeight(FontWeight.Medium);
          Text('记账总笔数')
            .fontSize(12)
            .fontColor($r('app.color.font_color_level2'));
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center);
      }
      .width('100%')
    };
  }
}
