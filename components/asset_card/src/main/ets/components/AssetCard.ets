import { AssetGroupModel, Constants, AssetRecordItem } from 'asset_base';
import { AssetCardItem } from './AssetCardItem';

@ComponentV2
export struct AssetCard {
  @Param
  assetData: AssetGroupModel = new AssetGroupModel();
  @Param
  anonymous: boolean = false;
  @Event
  handleDelete: (id: number) => void;
  @Event
  handleClick: (item: AssetRecordItem) => void;

  @Computed
  public get isValidData() {
    return this.assetData.fund.length || this.assetData.credit.length;
  }

  build() {
    if (!this.isValidData) {
      this.emptyCardBuilder();
    } else {
      this.assetListBuilder();
    }
  }

  @Builder
  emptyCardBuilder() {
    Column() {
      Image($r('app.media.ic_empty_card'))
        .width(80)
        .height(80)
        .margin({ bottom: 8 });
      Text('暂无记录')
        .fontSize(14)
        .fontWeight(FontWeight.Regular)
        .fontColor(Constants.FONT_COLOR_LEVEL2);
    }
    .padding(16)
    .backgroundColor(Constants.BACKGROUND_COLOR)
    .borderRadius(Constants.BORDER_RADIUS_16)
    .width('100%');
  }

  @Builder
  assetListBuilder() {
    List({ space: 8 }) {
      if (this.assetData.fund.length) {
        ListItemGroup({
          header: this.assetGroupHeader('资产账户', this.getGroupAmount(this.assetData.fund)),
        }) {
          ForEach(this.assetData.fund, (item: AssetRecordItem) => {
            ListItem() {
              AssetCardItem({
                assetItem: item,
                anonymous: this.anonymous,
              });
            }
            .onClick(() => {
              this.handleClick?.(item);
            })
            .swipeAction({ end: this.itemEndBuilder(item.assetId) });
          }, (item: AssetRecordItem) => JSON.stringify(item));
        }
        .assetGroupStyle();
      }

      if (this.assetData.credit.length) {
        ListItemGroup({
          header: this.assetGroupHeader('信用账户',
            this.getGroupAmount(this.assetData.credit)),
        }) {
          ForEach(this.assetData.credit, (item: AssetRecordItem) => {
            ListItem() {
              AssetCardItem({
                assetItem: item,
                anonymous: this.anonymous,
              });
            }
            .onClick(() => {
              this.handleClick?.(item);
            })
            .swipeAction({ end: this.itemEndBuilder(item.assetId) });
          }, (item: AssetRecordItem) => JSON.stringify(item));
        }
        .assetGroupStyle();
      }
    }
    .backgroundColor(Constants.BACKGROUND_COLOR)
    .padding(16)
    .borderRadius(Constants.BORDER_RADIUS_16);

  }

  @Builder
  assetGroupHeader(title: string, amount: string) {
    Row() {
      Text(title)
        .fontColor(Constants.FONT_COLOR_LEVEL1)
        .fontSize(Constants.FONT_SIZE_18)
        .fontWeight(FontWeight.Bold);
      Text(this.anonymous ? '**' : amount)
        .fontSize(Constants.FONT_SIZE_14)
        .fontColor(Constants.FONT_COLOR_LEVEL2)
        .fontWeight(FontWeight.Regular);
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .margin({ top: 8, bottom: 4 });
  }

  @Builder
  itemEndBuilder(id: number) {
    Row() {
      Text('删除')
        .fontSize(Constants.FONT_SIZE_14)
        .fontColor(Constants.FONT_COLOR_1_INVERT);
    }
    .padding(16)
    .margin({ left: 16 })
    .backgroundColor(Constants.WARNING_COLOR)
    .onClick(() => {
      this.handleDelete?.(id);
    })
    .height('100%');
  }

  getGroupAmount(list: AssetRecordItem[]) {
    const amount = list.reduce((pre, cur) => pre + cur.amount, 0);
    const symbol = amount >= 0 ? '+' : '';
    return symbol + amount.toFixed(2);
  }
}

@Extend(ListItemGroup)
function assetGroupStyle() {
  .divider({
    strokeWidth: 0.5,
    color: Constants.DIVIDER_COLOR,
    startMargin: 40,
  });
}