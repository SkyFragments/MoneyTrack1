import { RouterMap, DialogMap } from './Constants';

export interface NavRouterInfo {
  url: RouterMap | DialogMap;
  mode?: NavDestinationMode;
  param?: ESObject;
  onPop?: Callback<PopInfo>;
}

export interface DialogInfo<T = Object | undefined> {
  name?: DialogMap;
  param?: T;
  onPop?: Callback<PopInfo>;
}

export interface ConfirmDialogOption {
  title: string;
  message: string;
}
