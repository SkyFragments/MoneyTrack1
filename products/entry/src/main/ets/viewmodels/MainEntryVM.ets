import { emitter } from '@kit.BasicServicesKit';
import { AccountingDB } from 'bill_data_processing';
import {
  contextUtil,
  EventBus,
  EventKey,
  FrameworkUtil,
  RouterModule,
  WindowUtil,
} from 'commonlib';
import { TAB_LIST } from '../common/Constants';
import { WidgetUtil } from '../common/WidgetUtil';

@ObservedV2
export class MainEntryVM {
  // 路由栈实例
  @Trace navStack: NavPathStack = RouterModule.getStack();
  // tab页坐标
  @Trace curIndex: number = 0;
  tabController: TabsController = FrameworkUtil.tabController;
  private _widgetEventId: number = 1;
  private static _instance: MainEntryVM;

  @Computed
  public get tabTitle() {
    return TAB_LIST[this.curIndex].label;
  }

  public static get instance() {
    if (!MainEntryVM._instance) {
      MainEntryVM._instance = new MainEntryVM();
    }
    return MainEntryVM._instance;
  }

  // 初始化
  public async initData() {
    await AccountingDB.initialize(contextUtil.getContext()!);
    await WindowUtil.initWindowUtil();
    WidgetUtil.subscribeFormId(contextUtil.getContext()!);
    this.startEmitListener();
  }

  public startEmitListener() {
    try {
      emitter.on(
        {
          eventId: this._widgetEventId,
        },
        () => {
          WidgetUtil.updateWidgetsWhenChange();
        },
      );
    } catch (error) {
      WindowUtil.dealAllError(error);
    }
  }

  public cleanListener() {
    try {
      emitter.off(this._widgetEventId);
    }  catch (error) {
      WindowUtil.dealAllError(error);
    }
    EventBus.instance.off(EventKey.GLOBAL_REFRESH_EVENT);
  }
}
