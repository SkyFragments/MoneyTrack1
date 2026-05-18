import { AssetCard, AssetSummaryCard } from 'asset_card';
import { AddAssetButton } from 'bill_data_processing';
import { CommonHeader, RouterMap, RouterModule } from 'commonlib';
import { AssetsVM } from '../viewmodels/AssetsVM';

@ComponentV2
export struct AssetsView {
  vm: AssetsVM = new AssetsVM();

  aboutToAppear(): void {
    this.vm.initData();
  }

  build() {
    Column() {
      CommonHeader({
        title: '资产',
        icon: $r('app.media.ic_asset_analysis'),
        iconClick: () => { RouterModule.push({ url: RouterMap.ASSET_ANALYSIS }) }
      });

      Column({ space: 16 }) {
        AssetSummaryCard({
          anonymous: this.vm.anonymous,
          assetData: this.vm.assetProcessing.assetSummary,
          handleEyeClick: () => {
            this.vm.handleEyeClick();
          },
        });

        AddAssetButton({
          handleSuccess: () => {
            this.vm.assetProcessing.getAssetReport();
          },
        });
        Scroll() {
          Column() {
            AssetCard({
              anonymous: this.vm.anonymous,
              assetData: this.vm.assetProcessing.assetGroup,
              handleDelete: (id) => {
                this.vm.deleteAsset(id);
              },
              handleClick: (item) => {
                this.vm.jumpToDetailPage(item);
              },
            })
              .margin({ bottom: $r('app.string.space_l') });

            Blank().layoutWeight(1);
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Start);
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring);
      }
      .padding({
        left: $r('app.string.space_l'),
        right: $r('app.string.space_l'),
        top: $r('app.string.space_l'),
      })
      .layoutWeight(1);

    }
    .height($r('app.string.height_percent_full'))
    .width($r('app.string.width_percent_full'))
    .backgroundColor($r('app.color.system_color_background_auxiliary'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
  }
}
