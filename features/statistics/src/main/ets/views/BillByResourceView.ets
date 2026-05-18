import { BillCard } from 'bill_card';
import { DailyBillGroup } from 'bill_base';
import { CommonHeader, ContainerColumn } from 'commonlib';
import { BillByResourceVM } from '../viewmodels/BillByResourceVM';

@Builder
export function billByResourcePageBuilder() {
  BillByResourceView();
}

@Entry
@ComponentV2
struct BillByResourceView {
  vm: BillByResourceVM = new BillByResourceVM();

  build() {
    NavDestination() {
      CommonHeader();
      this.summaryCardBuilder();
      this.billListBuilder();
    }
    .onReady(() => {
      this.vm.initData();
    })
    .hideTitleBar(true)
    .backgroundColor($r('app.color.system_color_background_auxiliary'))
    .padding($r('app.string.space_l'));
  }

  @Builder
  summaryCardBuilder() {
    ContainerColumn({ alignStyle: HorizontalAlign.Center }) {
      Text(this.vm.summaryLabel)
        .fontSize($r('app.string.font_size_12'))
        .fontColor($r('app.color.font_color_level2'))
        .fontWeight(FontWeight.Regular)
        .margin({ bottom: $r('app.string.space_s') });
      Text(this.vm.summaryAmount)
        .fontSize($r('app.string.font_size_18'))
        .fontColor($r('app.color.font_color_level1'))
        .fontWeight(FontWeight.Bold);
    };
  }

  @Builder
  billListBuilder() {
    if (this.vm.resourceItem) {
      List() {
        ForEach(this.vm.dataProcessing.list, (item: DailyBillGroup) => {
          ListItem() {
            BillCard({
              showSummary: false,
              showOperation: false,
              card: item,
            });
          };
        }, (item: DailyBillGroup) => item.dateStr);
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
    }
  }
}