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
  public get global() {
    return PersistenceV2.connect(
      GlobalStateMgr,
      'GlobalStateMgr',
      () => new GlobalStateMgr(),
    )!
  }
}

const iData = new IData()

export { iData };
