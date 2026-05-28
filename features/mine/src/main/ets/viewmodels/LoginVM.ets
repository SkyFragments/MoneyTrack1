import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import * as wxopensdk from '@tencent/wechat_open_sdk';
import { UIDialog } from '@hw-agconnect/ui-dialog';
import { ToastDialog } from '@hw-agconnect/ui-toast';
import { LoginController, LoginParams, LoginChannelType } from 'aggregated_login';
import { iData, RouterModule, WindowUtil, AuthCache } from 'commonlib';
import { AuthApis } from 'lib_network';
import type { RegisterParams, UpgradeParams } from 'lib_network';
import { SyncApis } from 'lib_network';
import { MemberStatusUtil } from 'membership';
import { hilog } from '@kit.PerformanceAnalysisKit';

interface MeResponseData {
  id: string;
  email: string;
  username: string;
  createdAt: string;
}

interface SyncPullResult {
  accounts: object[];
  transactions: object[];
  assets: object[];
  budgets: object[];
  categories: object[];
  serverTime?: number | string;
}

const TAG = 'LoginVM';
const DOMAIN = 0x0000;

export class ProtocolData {
  static termOfServiceProtocol: string = 'TERMS_HTML_PLACEHOLDER';
  static privacyProtocol: string = 'PRIVACY_HTML_PLACEHOLDER';
  static huaweiUserProtocol: string = 'HUAWEI_HTML_PLACEHOLDER';
}

const ERROR_MSG_MAP: Record<number, string> = {
  1001502001: '用户未登录华为账号，请前往设置-登录华为账号。',
  1001500001: '应用指纹证书校验失败，请检查client_id、应用指纹证书配置。',
  1001502014: '应用未申请scopes或permissions权限。',
};

interface NonRenewItem {
  nonRenewList: string[];
}

export class LoginUtil {
  static controller: LoginController = new LoginController()

  static async huaweiLogin(loginParams: LoginParams): Promise<void> {
    const openId = loginParams?.unionID ?? '';
    if (!openId) {
      return;
    }
    try {
      const huaweiRes = await AuthApis.huaweiLogin({ openId });
      if (huaweiRes.code === 0 && huaweiRes.data) {
        const loginData = huaweiRes.data;
        AuthCache.clear();
        AuthCache.setTokens(loginData.accessToken, loginData.refreshToken);
        AuthCache.setUserId(loginData.user?.id ?? '');
        AuthCache.setUserType('full');
        iData.global.isLogin = true;
        iData.global.userInfo.reset();
        ToastDialog.showToast({ message: '华为一键登录成功' });
        const memberList = await MemberStatusUtil.queryPurchase(WindowUtil.context as common.UIAbilityContext);
        if (memberList.nonRenewList.length) {
          iData.global.userInfo.isMember = true;
        }
        // Fetch user profile from cloud
        try {
          const meRes = await AuthApis.me();
          if (meRes.code === 0 && meRes.data) {
            const meData = meRes.data as MeResponseData;
            iData.global.userInfo.name = meData.email;
            iData.global.userInfo.nickname = meData.username;
          } else {
            ToastDialog.showToast({ message: '获取用户信息失败' });
          }
        } catch (_e) {
          console.error('[LoginVM] huaweiLogin me() failed', _e);
          ToastDialog.showToast({ message: '获取用户信息失败' });
        }
        // Pull cloud data
        try {
          await LoginUtil.pullCloudData();
        } catch (_e) {
          console.error('[LoginVM] huaweiLogin pull() failed', _e);
          ToastDialog.showToast({ message: '同步云端数据失败' });
        }
        RouterModule.pop();
      } else {
        ToastDialog.showToast({ message: huaweiRes.msg || '登录失败' });
        // Close live Huawei session — user can't retry successfully without re-initiating
        LoginUtil.controller.signOut();
      }
    } catch (_error) {
      ToastDialog.showToast({ message: '网络错误，请稍后重试' });
      LoginUtil.controller.signOut();
    }
  }

  static async wxLogin(): Promise<void> {
    // TODO: implement WeChat login — currently shows placeholder
    ToastDialog.showToast({ message: '微信登录开发中' })
    return Promise.resolve()
  }

  static async verifyCodeLogin(loginParams: LoginParams): Promise<void> {
    UIDialog.open({
      contentOptions: {
        content: '验证码登录成功？',
        contentTextAlign: TextAlign.Center
      },
      showConfirmButton: true,
      showCancelButton: true,
      onConfirm: async () => {
        UIDialog.closeLast();
        LoginUtil.controller.clearLoginInfo();
        return LoginUtil.handleLoginEvent('验证码登录成功', loginParams, true)
      }
    })
  }

  static async obtainVerifyCode(phoneNumber: string): Promise<void> {
    try {
      await AuthApis.phoneLoginSend({ phoneNumber })
      ToastDialog.showToast({ message: '验证码已发送' })
    } catch (error) {
      ToastDialog.showToast({ message: '发送失败，请稍后重试' })
    }
  }

  static async handleLoginEvent(msg: string, loginParams?: LoginParams, isOtherPage: boolean = false): Promise<void> {
    if (loginParams?.unionID) {
      await LoginUtil.huaweiLogin(loginParams);
      return;
    }
    try {
      const phoneRes = await AuthApis.phoneLogin({
        phoneNumber: loginParams?.phoneNumbers ?? '',
        code: loginParams?.verifyCode ?? ''
      });
      if (phoneRes.code === 0 && phoneRes.data) {
        AuthCache.clear();
        AuthCache.setTokens(phoneRes.data.accessToken, phoneRes.data.refreshToken);
        AuthCache.setUserId(phoneRes.data.user?.id ?? '');
        AuthCache.setUserType('full');
        iData.global.isLogin = true;
        iData.global.userInfo.reset();
        ToastDialog.showToast({ message: msg });
        const memberList = await MemberStatusUtil.queryPurchase(WindowUtil.context as common.UIAbilityContext);
        if (memberList.nonRenewList.length) {
          iData.global.userInfo.isMember = true;
        }
        try {
          const meRes = await AuthApis.me();
          if (meRes.code === 0 && meRes.data) {
            const meData = meRes.data as MeResponseData;
            iData.global.userInfo.name = meData.email;
            iData.global.userInfo.nickname = meData.username;
          } else {
            ToastDialog.showToast({ message: '获取用户信息失败' });
          }
        } catch (_e) {
          console.error('[LoginVM] handleLoginEvent me() failed', _e);
          ToastDialog.showToast({ message: '获取用户信息失败' });
        }
        try {
          await LoginUtil.pullCloudData();
        } catch (_e) {
          console.error('[LoginVM] handleLoginEvent pull() failed', _e);
          ToastDialog.showToast({ message: '同步云端数据失败' });
        }
        if (isOtherPage) {
          if (loginParams?.phoneNumbers?.length === 11) {
            iData.global.userInfo.anonymousPhone =
              loginParams.phoneNumbers.slice(0, 3) + '****' + loginParams.phoneNumbers.slice(7);
          }
          RouterModule.pop();
        }
      } else {
        ToastDialog.showToast({ message: phoneRes.msg || '登录失败' });
        LoginUtil.controller.signOut();
      }
    } catch (_error) {
      ToastDialog.showToast({ message: '网络错误，请稍后重试' });
      LoginUtil.controller.signOut();
    }
  }

  static handleLoginFail(loginChannelType: LoginChannelType, error: BusinessError | wxopensdk.BaseResp): void {
    if (loginChannelType === LoginChannelType.HUAWEI) {
      const businessError = error as BusinessError
      const errorMsg = ERROR_MSG_MAP[businessError.code] ?? '未知错误。';
      // SDK-level errors (cert/scope issues) cannot be retried — retry would fail same way
      ToastDialog.showToast({ message: errorMsg + '（无法重试）' });
      LoginUtil.controller.signOut();
    } else if (loginChannelType === LoginChannelType.WECHAT) {
      ToastDialog.showToast({ message: '微信登录失败，请稍后重试' })
    }
  }

  static async registerUser(username: string, password: string): Promise<boolean> {
    try {
      const res = await AuthApis.register({ username, password })
      if (res.code === 0 && res.data) {
        AuthCache.clear();
        AuthCache.setTokens(res.data.accessToken, res.data.refreshToken)
        AuthCache.setUserId(res.data.user?.id ?? '')
        AuthCache.setUserType('full')
        iData.global.isLogin = true
        iData.global.userInfo.reset()
        // Fetch user profile from cloud
        try {
          const meRes = await AuthApis.me();
          if (meRes.code === 0 && meRes.data) {
            const meData = meRes.data as MeResponseData;
            iData.global.userInfo.name = meData.email;
            iData.global.userInfo.nickname = meData.username;
          }
        } catch (_e) {
          console.error('[LoginVM] registerUser me() failed', _e);
        }
        // Pull cloud data
        try {
          await LoginUtil.pullCloudData();
        } catch (_e) {
          console.error('[LoginVM] registerUser pull() failed', _e);
        }
        RouterModule.pop()
        return true
      }
      throw new Error(res.msg || '注册失败，code=' + res.code)
    } catch (_err) {
      const msg = _err instanceof Error ? _err.message : String(_err)
      console.error('[LoginVM] registerUser error:', msg)
      throw new Error(msg)
    }
  }

  static async handleRegister(params: RegisterParams, registerConfirmPassword: string): Promise<void> {
    if (params.password !== registerConfirmPassword) {
      ToastDialog.showToast({ message: '两次密码不一致' })
      return
    }
    if (params.username.length < 3 || params.username.length > 30) {
      ToastDialog.showToast({ message: '用户名需3-30字符' })
      return
    }
    if (params.password.length < 6) {
      ToastDialog.showToast({ message: '密码至少6字符' })
      return
    }

    try {
      const res = await AuthApis.register(params)
      if (res.code === 0 && res.data) {
        AuthCache.clear();
        AuthCache.setTokens(res.data.accessToken, res.data.refreshToken)
        AuthCache.setUserId(res.data.user?.id ?? '')
        AuthCache.setUserType('full')
        iData.global.isLogin = true
        iData.global.userInfo.reset()
        ToastDialog.showToast({ message: '注册成功' })
        // Fetch user profile from cloud
        try {
          const meRes = await AuthApis.me();
          if (meRes.code === 0 && meRes.data) {
            const meData = meRes.data as MeResponseData;
            iData.global.userInfo.name = meData.email;
            iData.global.userInfo.nickname = meData.username;
          }
        } catch (_e) {
          console.error('[LoginVM] handleRegister me() failed', _e);
        }
        // Pull cloud data
        try {
          await LoginUtil.pullCloudData();
        } catch (_e) {
          console.error('[LoginVM] handleRegister pull() failed', _e);
        }
        RouterModule.pop()
      } else {
        ToastDialog.showToast({ message: res.msg || '注册失败' })
      }
    } catch (error) {
      ToastDialog.showToast({ message: '网络错误，请稍后重试' })
    }
  }

  static checkGuestMode(): boolean {
    const userType = AuthCache.getUserType();
    hilog.info(DOMAIN, TAG, 'checkGuestMode: userType=%{public}s', userType);
    return userType === 'guest';
  }

  static async handleUpgrade(params: RegisterParams): Promise<boolean> {
    // Validate
    if (!params.username || params.username.length < 3 || params.username.length > 30) {
      ToastDialog.showToast({ message: '用户名需3-30字符' })
      return false
    }
    if (!params.password || params.password.length < 6) {
      ToastDialog.showToast({ message: '密码至少6字符' })
      return false
    }

    try {
      const res = await AuthApis.upgrade(params as UpgradeParams)
      if (res.code === 0 && res.data) {
        AuthCache.clear();
        AuthCache.setTokens(res.data.accessToken, res.data.refreshToken)
        AuthCache.setUserId(res.data.user?.id ?? '')
        AuthCache.setUserType('full')
        iData.global.isLogin = true
        iData.global.userInfo.reset()
        ToastDialog.showToast({ message: '升级成功' })
        // Fetch user profile from cloud
        try {
          const meRes = await AuthApis.me();
          if (meRes.code === 0 && meRes.data) {
            const meData = meRes.data as MeResponseData;
            iData.global.userInfo.name = meData.email;
            iData.global.userInfo.nickname = meData.username;
          }
        } catch (_e) {
          console.error('[LoginVM] handleUpgrade me() failed', _e);
        }
        // Pull cloud data (await to ensure data is loaded before returning)
        try {
          await LoginUtil.pullCloudData();
        } catch (_e) {
          console.error('[LoginVM] handleUpgrade pull() failed', _e);
        }
        return true
      } else {
        ToastDialog.showToast({ message: res.msg || '升级失败' })
        return false
      }
    } catch (_error) {
      ToastDialog.showToast({ message: '网络错误，请稍后重试' })
      return false
    }
  }

  static async pullCloudData(): Promise<void> {
    try {
      const res = await SyncApis.pull();
      if (res.code === 0 && res.data) {
        const data = res.data as SyncPullResult;
        if (data.serverTime) {
          const serverTime = Number(data.serverTime) || 0;
          if (serverTime > 0) {
            AuthCache.setLastSyncTime(serverTime);
          }
        }
      }
    } catch (_e) {
      console.error('[LoginUtil] pullCloudData failed', _e);
    }
  }
}
