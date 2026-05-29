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
      Logger.info(TAG, 'validateAuth: no token, skipping');
      return;
    }
    Logger.info(TAG, 'validateAuth: token exists, calling me()...');
    try {
      const res = await AuthApis.me();
      Logger.info(TAG, 'validateAuth: me() response code=%{public}d', res.code);
      if (res.code !== 0) {
        Logger.info(TAG, 'validateAuth: me() returned error, clearing auth');
        this.clearAuthState();
      } else {
        Logger.info(TAG, 'validateAuth: token valid, keeping auth state');
      }
    } catch (err) {
      Logger.info(TAG, 'validateAuth: me() threw exception % {public}s — NOT clearing auth on network error', String(err));
      // Network error — do NOT clear auth state. Token might still be valid.
      // Only clear on explicit server rejection (code !== 0).
    }
  }

  clearAuthState(): void {
    // Only clear if token exists — if no token, user was never logged in, nothing to clear
    const token = AuthCache.getAccessToken();
    if (!token) {
      Logger.info(TAG, 'clearAuthState skipped — no token to clear');
      return;
    }
    Logger.info(TAG, 'clearAuthState clearing auth state');
    AuthCache.clear();
    iData.global.isLogin = false;
    iData.global.userInfo.reset();
  }
}
