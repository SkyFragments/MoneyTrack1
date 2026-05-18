import { RouterModule } from '../router/Index';

export enum TabIndexMap {
  HOME,
  STATISTICS,
  ASSETS,
  MINE,
}

@ObservedV2
export class FrameworkUtil {
  @Trace static currentIndex: number = 0;
  static tabController: TabsController = new TabsController();

  public static switchTab(tab: TabIndexMap) {
    FrameworkUtil.tabController?.changeIndex(tab);
    FrameworkUtil.currentIndex = tab;
  }

  public static backToHome() {
    RouterModule.clear();
    FrameworkUtil.switchTab(TabIndexMap.HOME);
  }
}
