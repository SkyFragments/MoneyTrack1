import { PersistenceV2 } from '@kit.ArkUI';
import { UserInfoModel } from './Model';

@ObservedV2
export class GlobalStateMgr {
  @Trace
  public isLogin: boolean = false;
  @Trace
  public userInfo: UserInfoModel = new UserInfoModel();
}

class IData {
  private static _global: GlobalStateMgr | null = null;

  public get global(): GlobalStateMgr {
    if (!IData._global) {
      const connected = PersistenceV2.connect(
        GlobalStateMgr,
        'GlobalStateMgr',
        () => new GlobalStateMgr(),
      );
      // If connect returns a fresh blank model (app restart with empty store),
      // keep existing _global if it has data. Otherwise use the fresh one.
      if (connected) {
        if (connected.isLogin || connected.userInfo.nickname !== '') {
          IData._global = connected;
        } else if (!IData._global) {
          IData._global = connected;
        }
      } else if (!IData._global) {
        IData._global = new GlobalStateMgr();
      }
    }
    return IData._global!;
  }
}

const iData = new IData()

export { iData };
