import {
  AssetGroup,
  AssetRecordItem,
  Constants,
} from 'asset_base';

/**
 * 资产筛选弹窗选项
 */
export interface AssetFilterSheetOptions {
  // 当前已选中的资产 ID 集合
  currentSelection: Set<number>;
  // 资产分组数据
  assetGroup: AssetGroup;
  // 选中集合变化回调
  selectionChange: (selectedIds: Set<number>) => void;
}

@Builder
export function assetFilterSheetBuilder(options: AssetFilterSheetOptions) {
  AssetFilterSheet({
    currentSelection: options.currentSelection,
    assetGroup: options.assetGroup,
    selectionChange: options.selectionChange,
  });
}

@ComponentV2
export struct AssetFilterSheet {
  @Param
  currentSelection: Set<number> = new Set();

  @Param
  assetGroup: AssetGroup = { fund: [], credit: [] };

  @Event
  selectionChange: (selectedIds: Set<number>) => void;

  @Local
  private _selectedIds: Set<number> = new Set();

  // 计算属性：总资产数量
  @Computed
  get totalAssetCount(): number {
    return this.assetGroup.fund.length + this.assetGroup.credit.length;
  }

  aboutToAppear(): void {
    // 初始化本地选中状态
    this._selectedIds = new Set(this.currentSelection);
    this.selectionChange?.(new Set(this._selectedIds));
  }

  build() {
    Column() {
      // 头部区域
      this.headerBuilder();

      // 内容滚动区域
      Scroll() {
        Column() {
          // 资金账户列表
          if (this.assetGroup.fund && this.assetGroup.fund.length > 0) {
            Text('资金账户')
              .fontSize(14)
              .fontColor(Constants.FONT_COLOR_LEVEL1)
              .textAlign(TextAlign.Start)
              .width('100%')
              .margin({ left: 16, right: 16, top: 16, bottom: 8 });
            this.groupBuilder(this.assetGroup.fund);
          }

          // 信用账户列表
          if (this.assetGroup.credit && this.assetGroup.credit.length > 0) {
            Text('信用账户')
              .fontSize(14)
              .fontColor(Constants.FONT_COLOR_LEVEL1)
              .textAlign(TextAlign.Start)
              .width('100%')
              .margin({ left: 16, right: 16, top: 16, bottom: 8 });
            this.groupBuilder(this.assetGroup.credit);
          }

          if (this.totalAssetCount === 0) {
            Column() {
              Image($r('app.media.ic_empty_asset_bill'))
                .width(80)
                .height(80)
                .opacity(0.5);
              Text('暂无资产账户')
                .fontSize(14)
                .fontColor(Constants.FONT_COLOR_LEVEL2)
                .margin({ top: 16 });
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .padding({ top: 50, bottom: 50 });
          }
        }
        .width('100%');
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor(Constants.BACKGROUND_COLOR_GREY);
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor(Constants.BACKGROUND_COLOR_GREY);
  }

  @Builder
  headerBuilder() {
    Row() {
      Text('全部账户')
        .fontWeight(FontWeight.Medium)
        .fontColor(Constants.FONT_COLOR_LEVEL1)
        .layoutWeight(1);

      CheckboxGroup({ group: 'asset_filter_group' })
        .selectedColor(Constants.THEME_COLOR);
    }
    .width('100%')
    .padding(16)
    .borderRadius(16)
    .backgroundColor(Color.White);
  }

  @Builder
  groupBuilder(list: AssetRecordItem[]) {
    List({ space: 8 }) {
      ForEach(list, (item: AssetRecordItem) => {
        ListItem() {
          Row() {
            // 图标
            Image(item.icon)
              .width(24)
              .height(24)
              .borderRadius(4)
              .margin({ right: 12 });

            // 名称和备注
            Column() {
              Text(item.name)
                .fontSize(16)
                .fontColor(Constants.FONT_COLOR_LEVEL1)

              if (item.note) {
                Text(item.note)
                  .fontSize(12)
                  .fontColor(Constants.FONT_COLOR_LEVEL3)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 2 });
              }
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start);

            Checkbox({ name: item.assetId.toString(), group: 'asset_filter_group' })
              .select(this._selectedIds.has(item.assetId))
              .selectedColor(Constants.THEME_COLOR)
              .onChange((checked: boolean) => {
                const ids = new Set(this._selectedIds);
                if (checked) {
                  ids.add(item.assetId);
                } else {
                  ids.delete(item.assetId);
                }
                this._selectedIds = ids;
                this.selectionChange?.(new Set(this._selectedIds));
              });
          }
          .width('100%')
          .height(56)
          .backgroundColor($r('sys.color.comp_background_list_card'));
        }
      }, (item: AssetRecordItem) => item.assetId.toString());
    }
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .borderRadius(16)
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .assetGroupStyle();
  }
}

@Extend(List)
function assetGroupStyle() {
  .divider({
    strokeWidth: 0.5,
    color: Constants.DIVIDER_COLOR,
    startMargin: 40,
  });
}
