import { UIDialog } from '@hw-agconnect/ui-dialog';
import { ToastDialog } from '@hw-agconnect/ui-toast';
import {
  AboutModel,
  SettingGroup,
  SettingItem,
  SettingType,
  SettingView,
  SupportedSetting,
  WebModel,
} from 'app_setting';
import { RouterModule, RouterMap, CommonHeader, iData } from 'commonlib'
import { UserApis } from 'lib_network';

@ComponentV2
export struct SettingPage {
  @Local
  stack: NavPathStack = RouterModule.getStack()
  @Local
  group1: SettingGroup = new SettingGroup()
    .setList([
      new SettingItem()
        .setType(SettingType.ROUTER)
        .setLabel('个人信息')
        .setRouterParam({ routerName: RouterMap.USER_PROFILE_EDIT }),
    ])
  @Local
  group2: SettingGroup = new SettingGroup()
    .setList([
      new SettingItem()
        .setSupportedType(SupportedSetting.CLEAR_CACHE),
    ])
  @Local
  group3: SettingGroup = new SettingGroup()
    .setTitle('了解我们如何使用您的数据')
    .setList([
      new SettingItem()
        .setSupportedType(SupportedSetting.WEB)
        .setLabel('业务与隐私的声明')
        .setExtraParams({ src: 'resource://rawfile/static/html/privacy-policy.html' } as WebModel),
      new SettingItem()
        .setSupportedType(SupportedSetting.WEB)
        .setLabel('第三方共享信息清单')
        .setExtraParams({ src: 'resource://rawfile/static/html/third-party-info.html' } as WebModel),
      new SettingItem()
        .setSupportedType(SupportedSetting.WEB)
        .setLabel('第三方SDK列表')
        .setExtraParams({ src: 'resource://rawfile/static/html/third-sdk.html' } as WebModel),
      new SettingItem()
        .setSupportedType(SupportedSetting.WEB)
        .setLabel('已收集个人信息清单')
        .setExtraParams({ src: 'resource://rawfile/static/html/personal-info-collection.html' } as WebModel),
      new SettingItem()
        .setSupportedType(SupportedSetting.WEB)
        .setLabel('隐私声明摘要')
        .setExtraParams({ src: 'resource://rawfile/static/html/privacy-policy.html' } as WebModel),
    ])
  @Local
  group4: SettingGroup = new SettingGroup()
    .setTitle('更多')
    .setList([
      new SettingItem()
        .setSupportedType(SupportedSetting.ABOUT)
        .setExtraParams({
          icpText: '苏ICP备xxxx号-xxx',
          copyrightText: '华为xx 版权所有 © 2019-2026',
          hotline: '00000000',
        } as AboutModel),
      new SettingItem()
        .setSupportedType(SupportedSetting.WEB)
        .setLabel('服务协议与规则')
        .setExtraParams({ src: 'resource://rawfile/static/html/user-agreement.html' } as WebModel),
    ])

  public build(): void {
    NavDestination() {
      Column() {
        CommonHeader({ title: '设置' })

        SettingView({
          pathStack: this.stack,
          settingList: [this.group1, this.group2, this.group3, this.group4],
        })
          .layoutWeight(1)
        if (iData.global.isLogin) {
          Row() {
            Button('退出登录')
              .width('100%')
              .constraintSize({ maxWidth: 360 })
              .fontColor($r('sys.color.font_primary'))
              .backgroundColor($r('sys.color.comp_background_tertiary'))
              .onClick(() => {
                UIDialog.open({
                  contentOptions: { content: '确认退出账号登录吗？', },
                  showConfirmButton: true,
                  showCancelButton: true,
                  onConfirm: async () => {
                    UIDialog.closeLast();
                    const res = await UserApis.logout();
                    if (res.code === 0) {
                      ToastDialog.showToast({ message: '已退出登录' });
                      RouterModule.pop();
                    }
                  }
                })
              },
              )
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ left: 28, right: 28 })
          .margin({ top: 12, bottom: 12 })
        }
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)
      .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.CUTOUT], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .backgroundColor('#FFF1F3F5')
    }
    .hideTitleBar(true)
  }
}

@Builder
export function buildSettingPage() {
  SettingPage();
}