import { TabListItem } from './Types';

export const TAB_LIST: TabListItem[] = [
  {
    label: '明细',
    icon: $r('app.media.ic_tab_bill'),
    iconChecked: $r('app.media.ic_tab_bill_checked'),
  },
  {
    label: '统计',
    icon: $r('app.media.ic_tab_charts'),
    iconChecked: $r('app.media.ic_tab_charts_checked'),
  },
  {
    label: '资产',
    icon: $r('app.media.ic_tab_assets'),
    iconChecked: $r('app.media.ic_tab_assets_checked'),
  },
  {
    label: '我的',
    icon: $r('app.media.ic_tab_mine'),
    iconChecked: $r('app.media.ic_tab_mine_checked'),
  },
];
