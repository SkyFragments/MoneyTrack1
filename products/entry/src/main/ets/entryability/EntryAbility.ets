import { ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { contextUtil, FrameworkUtil, Logger, TabIndexMap, WindowUtil, AuthCache, iData } from 'commonlib';
import { AuthApis } from 'lib_network';

const TAG: string = '[EntryAbility]';

export default class EntryAbility extends UIAbility {
  public onCreate(want: Want): void {
    try {
      this.context
        .getApplicationContext()
        .setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    } catch (error) {
      WindowUtil.dealAllError(error);
    }
    this.handleWantInfo(want);
  }

  // 如果UIAbility已在后台运行，在收到Router事件后会触发onNewWant生命周期回调
  public onNewWant(want: Want): void {
    this.handleWantInfo(want);
  }

  public onWindowStageCreate(windowStage: window.WindowStage): void {
    this.validateAuth();
    Logger.info(TAG, 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/MainEntry', (err) => {
      if (err.code) {
        Logger.error(TAG, 'Failed to load the content.' + JSON.stringify(err));
        return;
      }
      Logger.info(TAG, 'Succeeded in loading the content.');
      contextUtil.setUiContext(windowStage.getMainWindowSync().getUIContext());
    });
  }

  public handleWantInfo(want: Want) {
    if (want?.parameters?.params) {
      try {
        let params: Record<string, Object> = JSON.parse(
          want.parameters.params as string,
        );
        const cardType = params.cardType as string;
        const message = params.message as string;
        if (cardType === 'middle' && message === 'assets') {
          FrameworkUtil.switchTab(TabIndexMap.ASSETS);
          return;
        }
        FrameworkUtil.switchTab(TabIndexMap.HOME);
      } catch (err) {
        Logger.error('get want parameters failed.' + JSON.stringify(err));
      }
    }
  }

  async validateAuth(): Promise<void> {
    const token = AuthCache.getAccessToken();
    if (!token) {
      return;
    }
    try {
      const res = await AuthApis.me();
      if (res.code !== 0) {
        this.clearAuthState();
      }
    } catch {
      this.clearAuthState();
    }
  }

  clearAuthState(): void {
    AuthCache.clear();
    iData.global.isLogin = false;
    iData.global.userInfo.reset();
  }
}
