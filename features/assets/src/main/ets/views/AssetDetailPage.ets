import { emitter } from '@kit.BasicServicesKit';
import { DailyBillGroup } from 'bill_base';
import { BillCard } from 'bill_card';
import { CommonHeader, ContainerColumn, EventBus, EventKey, RouterModule, WindowUtil } from 'commonlib';
import { CreateBillButton, ASSET_CHANGE_EVENT_ID } from 'bill_data_processing';
import { AssetDetailVM } from '../viewmodels/AssetDetailVM';

@Builder
export function assetDetailPageBuilder() {
  AssetDetailPage();
}

@Entry
@ComponentV2
struct AssetDetailPage {
  vm: AssetDetailVM = new AssetDetailVM();

  build() {
    NavDestination() {
      CommonHeader({
        title: this.vm.assetItem?.name ?? '',
        backButtonClick: () => {
          try {
            emitter.emit({ eventId: ASSET_CHANGE_EVENT_ID });
          } catch (error) {
            WindowUtil.dealAllError(error);
          }
        }
      });
      Column() {
        this.summaryCardBuilder();
        this.billListBuilder();
      }
      .padding($r('app.string.space_l'));

      // 记一笔
      CreateBillButton({
        assetId: this.vm.assetItem?.assetId,
        accountId: this.vm.billProcessing.currentAccountId,
        handleCreateSuccess: () => {
          this.vm.refreshData();
          EventBus.instance.emit(EventKey.GLOBAL_REFRESH_EVENT);
        },
      });
    }
    .backgroundColor($r('app.color.system_color_background_auxiliary'))
    .hideTitleBar(true)
    .onReady(() => {
      this.vm.initData();
    })
    .onBackPressed(() => {
      try {
        emitter.emit({ eventId: ASSET_CHANGE_EVENT_ID });
      } catch (error) {
        WindowUtil.dealAllError(error);
      }
      RouterModule.pop(1);
      return true;
    });
  }

  @Builder
  summaryCardBuilder() {
    ContainerColumn({ alignStyle: HorizontalAlign.Center }) {
      Text('金额')
        .fontSize($r('app.string.font_size_12'))
        .fontColor($r('app.color.font_color_level2'))
        .fontWeight(FontWeight.Regular)
        .margin({ bottom: $r('app.string.space_s') });

      Row() {
        Text(this.vm.totalAmount.toFixed(2))
          .fontSize($r('app.string.font_size_18'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.font_color_level1'))
          .margin({ top: $r('app.string.space_xxs'), right: $r('app.string.space_xs') });
        Image($r('app.media.ic_asset_edit'))
          .width(16)
          .height(16)
          .onClick(() => {
            this.vm.editAsset();
          });
      };

    };
  }

  @Builder
  billListBuilder() {
    if (!this.vm.billProcessing.list?.length) {
      Column() {
        Image($r('app.media.ic_empty_asset_bill'))
          .width(120)
          .height(120)
          .margin({
            top: $r('app.string.space_xl'),
            bottom: $r('app.string.space_s'),
          });
        Text('该账户暂无记录')
          .fontSize($r('app.string.font_size_14'))
          .fontColor($r('app.color.font_color_level2'));
      };
    } else {
      List() {
        ForEach(this.vm.billProcessing.list, (item: DailyBillGroup) => {
          ListItem() {
            BillCard({
              card: item,
              showAsset: false,
            });
          };
        }, (item: DailyBillGroup) => JSON.stringify(item));
      };
    }
  }
}