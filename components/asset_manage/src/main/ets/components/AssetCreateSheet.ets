import { AssetDisplayTypeItem, AssetType, Constants } from 'asset_base';


export interface AssetCreateSheetOptions {
  assetTypeList: AssetDisplayTypeItem[];
  handleClick?: (subType: number) => void;
}

@Builder
export function assetCreateSheetBuilder(options: AssetCreateSheetOptions) {
  AssetCreateSheet({
    assetTypeList: options.assetTypeList,
    handleClick: options.handleClick,
  });
}

@ComponentV2
export struct AssetCreateSheet {
  @Param
  bgColor: ResourceColor = Constants.BACKGROUND_COLOR;
  @Param
  assetTypeList: AssetDisplayTypeItem[] = [];
  @Event
  handleClick: (type: AssetType, subType?: number) => void;

  @Computed
  public get assetList() {
    return this.assetTypeList.filter((item) => item.type === AssetType.FUND);
  }

  @Computed
  public get liabilityList() {
    return this.assetTypeList.filter((item) => item.type === AssetType.CREDIT);
  }

  build() {
    Scroll() {
      Column() {
        this.assetGroupBuilder('资金账户', AssetType.FUND, this.assetList);
        this.assetGroupBuilder('信用账户', AssetType.CREDIT, this.liabilityList);
      };
    }
    .align(Alignment.TopStart)
    .edgeEffect(EdgeEffect.Spring)
    .padding(16)
    .backgroundColor(this.bgColor)
    .width('100%')
    .height('100%');
  }

  @Builder
  assetGroupBuilder(title: string, type: AssetType, list: AssetDisplayTypeItem[]) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontColor(Constants.FONT_COLOR_LEVEL1)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 16 });
      Grid() {
        ForEach(list, (item: AssetDisplayTypeItem) => {
          GridItem() {
            Column() {
              Image(item.icon)
                .width(40)
                .height(40)
                .borderRadius(20)
                .margin({ bottom: 4 });
              Text(item.name)
                .fontSize(12)
                .fontColor(Constants.FONT_COLOR_LEVEL1)
                .fontWeight(FontWeight.Regular);
            };
          }
          .onClick(() => {
            this.handleClick?.(type, item.subType);
          });
        }, (item: AssetDisplayTypeItem, index: number) => index + '__' + item.name);
        GridItem() {
          Column() {
            Image($r('app.media.ic_asset_add'))
              .width(40)
              .height(40)
              .margin({ bottom: 4 });
            Text('自定义')
              .fontSize(12)
              .fontColor(Constants.FONT_COLOR_LEVEL1)
              .fontWeight(FontWeight.Regular);
          };
        }
        .onClick(() => {
          this.handleClick?.(type);
        });
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
      .rowsGap(16);
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 24 });
  }
}