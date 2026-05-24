import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import * as wxopensdk from '@tencent/wechat_open_sdk';
import { UIDialog } from '@hw-agconnect/ui-dialog';
import { ToastDialog } from '@hw-agconnect/ui-toast';
import { LoginController, LoginParams, LoginChannelType, RegisterParams } from 'aggregated_login';
import { iData, RouterModule, WindowUtil, AuthCache } from 'commonlib';
import { AuthApis } from 'lib_network';
import { MemberStatusUtil } from 'membership';
import { hilog } from '@kit.PerformanceAnalysisKit';

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
    // Huawei login: use openId from loginParams to call huaweiLogin API directly.
    // handleLoginEvent splits on unionID falsiness — retry path has empty unionID → wrong branch.
    const openId = loginParams?.unionID ?? '';
    try {
      const huaweiRes = await AuthApis.huaweiLogin({ openId });
      if (huaweiRes.code === 0 && huaweiRes.data) {
        const loginData = huaweiRes.data;
        AuthCache.setTokens(loginData.accessToken, loginData.refreshToken);
        if (loginData.user?.id) {
          AuthCache.setUserId(loginData.user.id);
        }
        iData.global.isLogin = true;
        ToastDialog.showToast({ message: '华为一键登录成功' });
        const memberList = await MemberStatusUtil.queryPurchase(WindowUtil.context as common.UIAbilityContext);
        if (memberList.nonRenewList.length) {
          iData.global.userInfo.isMember = true;
        }
        RouterModule.pop();
      } else {
        ToastDialog.showToast({ message: huaweiRes.msg || '登录失败' });
      }
    } catch (_error) {
      ToastDialog.showToast({ message: '网络错误，请稍后重试' });
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
      try {
        const huaweiRes = await AuthApis.huaweiLogin({ openId: loginParams.unionID });
        if (huaweiRes.code === 0 && huaweiRes.data) {
          const loginData = huaweiRes.data;
          AuthCache.setTokens(loginData.accessToken, loginData.refreshToken);
          if (loginData.user?.id) {
            AuthCache.setUserId(loginData.user.id);
          }
          iData.global.isLogin = true;
          ToastDialog.showToast({ message: msg });
          const memberList = await MemberStatusUtil.queryPurchase(WindowUtil.context as common.UIAbilityContext);
          if (memberList.nonRenewList.length) {
            iData.global.userInfo.isMember = true;
          }
          RouterModule.pop();
          if (isOtherPage) {
            if (loginParams?.phoneNumbers?.length === 11) {
              iData.global.userInfo.anonymousPhone =
                loginParams.phoneNumbers.slice(0, 3) + '****' + loginParams.phoneNumbers.slice(7);
            }
            RouterModule.pop();
          }
        } else {
          ToastDialog.showToast({ message: huaweiRes.msg || '登录失败' });
        }
      } catch (_error) {
        ToastDialog.showToast({ message: '网络错误，请稍后重试' });
      }
    } else {
      try {
        const phoneRes = await AuthApis.phoneLogin({
          phoneNumber: loginParams?.phoneNumbers ?? '',
          code: loginParams?.verifyCode ?? ''
        });
        if (phoneRes.code === 0 && phoneRes.data) {
          AuthCache.setTokens(phoneRes.data.accessToken, phoneRes.data.refreshToken);
          if (phoneRes.data.user?.id) {
            AuthCache.setUserId(phoneRes.data.user.id);
          }
          iData.global.isLogin = true;
          ToastDialog.showToast({ message: msg });
          const memberList = await MemberStatusUtil.queryPurchase(WindowUtil.context as common.UIAbilityContext);
          if (memberList.nonRenewList.length) {
            iData.global.userInfo.isMember = true;
          }
          RouterModule.pop();
          if (isOtherPage) {
            if (loginParams?.phoneNumbers?.length === 11) {
              iData.global.userInfo.anonymousPhone =
                loginParams.phoneNumbers.slice(0, 3) + '****' + loginParams.phoneNumbers.slice(7);
            }
            RouterModule.pop();
          }
        } else {
          ToastDialog.showToast({ message: phoneRes.msg || '登录失败' });
        }
      } catch (_error) {
        ToastDialog.showToast({ message: '网络错误，请稍后重试' });
      }
    }
  }

  static handleLoginFail(loginChannelType: LoginChannelType, error: BusinessError | wxopensdk.BaseResp): void {
    if (loginChannelType === LoginChannelType.HUAWEI) {
      const businessError = error as BusinessError
      const errorMsg = ERROR_MSG_MAP[businessError.code] ?? '未知错误。';
      UIDialog.open({
        contentOptions: {
          content: errorMsg + '是否继续？',
          contentTextAlign: TextAlign.Center
        },
        showConfirmButton: true,
        showCancelButton: true,
        onConfirm: async () => {
          UIDialog.closeLast();
          LoginUtil.controller.clearLoginInfo();
          LoginUtil.huaweiLogin({} as LoginParams)
        },
      })
    } else if (loginChannelType === LoginChannelType.WECHAT) {
      ToastDialog.showToast({ message: '微信登录失败，请稍后重试' })
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
        AuthCache.setTokens(res.data.accessToken, res.data.refreshToken)
        AuthCache.setUserId(res.data.user.id)
        AuthCache.setUserType('full')
        iData.global.isLogin = true
        ToastDialog.showToast({ message: '注册成功' })
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
      const res = await AuthApis.upgrade(params)
      if (res.code === 0 && res.data) {
        AuthCache.setTokens(res.data.accessToken, res.data.refreshToken)
        AuthCache.setUserId(res.data.user?.id ?? '')
        AuthCache.setUserType('full')
        iData.global.isLogin = true
        ToastDialog.showToast({ message: '升级成功' })
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
