import { AssetCategory, AssetType } from './Enums';
import { AssetDisplayTypeItem } from './Types';

export class AssetConstants {
  public static readonly FONT_SIZE_12 = '12fp';
  public static readonly FONT_SIZE_14 = '14fp';
  public static readonly FONT_SIZE_16 = '16fp';
  public static readonly FONT_SIZE_18 = '18fp';
  public static readonly FONT_SIZE_24 = '24fp';
  public static readonly THEME_COLOR = '#94B982';
  public static readonly FONT_COLOR_LEVEL1 = '#E6000000';
  public static readonly FONT_COLOR_1_INVERT = '#FFFFFF';
  public static readonly FONT_COLOR_LEVEL2 = '#99000000';
  public static readonly FONT_COLOR_LEVEL3 = '#66000000';
  public static readonly DIVIDER_COLOR = '#33000000';
  public static readonly WARNING_COLOR = '#E84026';
  public static readonly BUTTON_BACKGROUND_COLOR_GREY = '#0D000000';
  public static readonly BACKGROUND_COLOR = '#FFFFFF';
  public static readonly BACKGROUND_COLOR_GREY = '#f1f3f5';
  public static readonly BORDER_RADIUS_16 = '16vp';
  public static readonly ASSET_TYPE_MAP: AssetDisplayTypeItem[] = [
    {
      name: '现金',
      type: AssetType.FUND,
      subType: 101,
      category: AssetCategory.ASSET,
      icon: $r('app.media.ic_asset_1'),
    },
    {
      name: '银行卡',
      type: AssetType.FUND,
      subType: 102,
      category: AssetCategory.ASSET,
      icon: $r('app.media.ic_asset_2'),
    },
    {
      name: '华为钱包',
      type: AssetType.FUND,
      subType: 103,
      category: AssetCategory.ASSET,
      icon: $r('app.media.ic_asset_3'),
    },
    {
      name: '支付宝',
      type: AssetType.FUND,
      subType: 104,
      category: AssetCategory.ASSET,
      icon: $r('app.media.ic_asset_4'),
    },
    {
      name: '微信',
      type: AssetType.FUND,
      subType: 105,
      category: AssetCategory.ASSET,
      icon: $r('app.media.ic_asset_5'),
    },
    {
      name: '云闪付',
      type: AssetType.FUND,
      subType: 106,
      category: AssetCategory.ASSET,
      icon: $r('app.media.ic_asset_6'),
    },
    {
      name: '数字人民币',
      type: AssetType.FUND,
      subType: 107,
      category: AssetCategory.ASSET,
      icon: $r('app.media.ic_asset_7'),
    },
    {
      name: '信用卡',
      type: AssetType.CREDIT,
      subType: 201,
      category: AssetCategory.LIABILITY,
      icon: $r('app.media.ic_liability_1'),
    },
    {
      name: '花呗',
      type: AssetType.CREDIT,
      subType: 202,
      category: AssetCategory.LIABILITY,
      icon: $r('app.media.ic_liability_2'),
    },
    {
      name: '美团月付',
      type: AssetType.CREDIT,
      subType: 203,
      category: AssetCategory.LIABILITY,
      icon: $r('app.media.ic_liability_3'),
    },
    {
      name: '抖音月付',
      type: AssetType.CREDIT,
      subType: 204,
      category: AssetCategory.LIABILITY,
      icon: $r('app.media.ic_liability_4'),
    },
    {
      name: '京东白条',
      type: AssetType.CREDIT,
      subType: 205,
      category: AssetCategory.LIABILITY,
      icon: $r('app.media.ic_liability_5'),
    },
  ];
}
