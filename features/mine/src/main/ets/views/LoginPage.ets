import {
  AggregatedLogin,
  Channel,
  ApiController,
  LoginType,
} from 'aggregated_login';
import { RouterModule } from 'commonlib';
import { LoginUtil, ProtocolData } from '../viewmodels/LoginVM';

@Builder
export function buildLoginPage() {
  LoginPage()
}

@ComponentV2
struct LoginPage {

  build() {
    NavDestination() {
      Column() {
        // 登录使用
        AggregatedLogin({
          routerModule: RouterModule.getStack(),
          icon: $r('app.media.app_icon'),
          themeColor: $r('app.color.system_theme_color'),
          isSheet: false,
          autoSheet: false,
          isPersistence: false,
          loginTypes: [new Channel(LoginType.WECHAT, '微信', {
            appId: 'xxx',
            scope: 'snsapi_userinfo,snsapi_friend,snsapi_message,snsapi_contact',
            transaction: 'test123',
            state: 'none',
          }, $r('app.media.wx_count'))],
          privacyContent: [{
            privacyLabel: '《用户协议》',
            privacyUrl: ProtocolData.termOfServiceProtocol,
            privacyTag: '用户协议',
          }, {
            privacyLabel: '《xxxx隐私政策》',
            privacyUrl: ProtocolData.privacyProtocol,
            privacyTag: '隐私政策',
          }, {
            privacyLabel: '《华为账号用户认证协议》',
            privacyUrl: ProtocolData.huaweiUserProtocol,
            privacyTag: '华为账号用户认证协议',
          }],
          apiController: new ApiController(
            LoginUtil.huaweiLogin,
            LoginUtil.wxLogin,
            LoginUtil.verifyCodeLogin
          ),
          handleLoginFail: LoginUtil.handleLoginFail,
          obtainVerifyCode: LoginUtil.obtainVerifyCode,
          loginController: LoginUtil.controller,
          registerUser: LoginUtil.registerUser,
        });
      }
    }
    .backgroundColor($r('sys.color.background_secondary'))
    .hideTitleBar(true)
  }
}