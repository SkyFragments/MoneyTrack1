import { SettingCard } from 'app_setting';
import { CommonHeader, ContainerColumn, iData, RouterMap, RouterModule } from 'commonlib';
import { BillInfoCard } from '../components/BillInfoCard';
import { MineVM } from '../viewmodels/MineVM';
import { LoginUtil } from '../viewmodels/LoginVM';
import { UIDialog } from '@hw-agconnect/ui-dialog';

@ComponentV2
export struct MineView {
  vm: MineVM = new MineVM();
  @Local showUpgradeDialog: boolean = false;
  @Local upgradeUsername: string = '';
  @Local upgradePassword: string = '';

  aboutToAppear(): void {
    // 加载记账统计信息
    this.vm.loadBillInfo();
  }

  aboutToDisappear(): void {
    if (this.showUpgradeDialog) {
      UIDialog.closeLast()
    }
  }

  build() {
    Column() {
      CommonHeader({ title: '我的' });

      Scroll() {
        Column({ space: 12 }) {
          this.userInfoArea();

          BillInfoCard({
            totalDays: this.vm.totalDays,
            totalBills: this.vm.totalBills,
          });

          this.serviceMenuArea();

          Blank().layoutWeight(1);
        }
      }
      .padding({
        left: $r('app.string.space_l'),
        right: $r('app.string.space_l'),
      })
      .layoutWeight(1);
    }
    .height($r('app.string.height_percent_full'))
    .width($r('app.string.width_percent_full'))
    .backgroundColor($r('app.color.system_color_background_auxiliary'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
  }

  @Builder userInfoArea() {
    ContainerColumn({ bottomGap: false }) {
      Row() {
        Image(iData.global.userInfo.avatar ? iData.global.userInfo.avatar : $r('app.media.default_avatar'))
          .width(48)
          .height(48)
          .borderRadius(48)
          .draggable(false)
          .margin({ right: 16 });
        Column() {
          Row() {
            Text(iData.global.isLogin ?
              iData.global.userInfo.nickname ? iData.global.userInfo.nickname : '华为用户' :
              '点击登录',
            )
              .fontWeight(FontWeight.Medium)
              .fontSize(18)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .textAlign(TextAlign.Start)
              .fontColor($r('app.color.font_color_level1'))
              .margin({ right: 8 })
            if (iData.global.isLogin) {
              Row() {
                SymbolGlyph($r('sys.symbol.v_diamond_fill'))
                  .fontColor([iData.global.userInfo.isMember ? $r('app.color.v_diamond_theme') :
                    $r('app.color.font_color_level3')])
                  .margin({ right: 2 })
                Text('会员')
                  .fontColor(iData.global.userInfo.isMember ? $r('app.color.font_color_level1') :
                    $r('app.color.font_color_level3'))
                  .fontSize(12)
              }
              .alignItems(VerticalAlign.Center)
            }
            if (LoginUtil.checkGuestMode()) {
              Text('本地模式')
                .fontSize($r('sys.float.Body_S'))
                .fontColor($r('sys.color.font_secondary'))
                .backgroundColor($r('sys.color.comp_background_tertiary'))
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .borderRadius(4)
                .margin({ left: 8 })
            }
          }.alignItems(VerticalAlign.Top)

          Row() {
            if (iData.global.isLogin) {
              Image($r('app.media.ic_mobile_phone'))
                .commonIconStyle()
                .margin({ right: 8 });
              Text(iData.global.userInfo.anonymousPhone).commonLabelStyle();
            }
          }
          .justifyContent(FlexAlign.Start)
          .alignItems(VerticalAlign.Center);
        }
        .layoutWeight(1)
        .height(48)
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.SpaceAround);

        Image($r('app.media.ic_arrow_right')).commonIconStyle();
      }
      .onClick(() => {
        if (!iData.global.isLogin) {
          RouterModule.push({ url: RouterMap.USER_LOGIN });
        } else {
          RouterModule.push({ url: RouterMap.USER_PROFILE_EDIT });
        }
      })

      if (iData.global.isLogin) {
        Divider().margin({ top: $r('app.string.space_m'), bottom: $r('app.string.space_m') })
        Row() {
          Text('开通VIP后享受更多服务').fontSize(14).fontColor($r('app.color.font_color_level1'))
          Button('会员中心')
            .controlSize(ControlSize.SMALL)
            .backgroundColor($r('app.color.v_diamond_theme'))
            .onClick(() => {
              RouterModule.push({ url: RouterMap.MEMBERSHIP })
            })
        }
        .width($r('app.string.width_percent_full'))
        .justifyContent(FlexAlign.SpaceBetween)
      }
      if (LoginUtil.checkGuestMode()) {
        Divider().margin({ top: $r('app.string.space_m'), bottom: $r('app.string.space_m') })
        Row() {
          Text('登录后可开启云同步').fontSize(14).fontColor($r('app.color.font_color_level1'))
          Button('升级到完整账号')
            .controlSize(ControlSize.SMALL)
            .backgroundColor($r('app.color.v_diamond_theme'))
            .onClick(() => {
              this.upgradeUsername = ''
              this.upgradePassword = ''
              UIDialog.open({
                contentBuilder: () => this.upgradeDialogBuilder(),
                confirmButtonOptions: {
                  button: '确认升级',
                  buttonFontColor: $r('app.color.v_diamond_theme'),
                },
                cancelButtonOptions: {
                  button: '取消',
                  buttonFontColor: $r('app.color.font_color_level1'),
                },
                onConfirm: async () => {
                  const success = await LoginUtil.handleUpgrade({
                    username: this.upgradeUsername,
                    password: this.upgradePassword
                  })
                  UIDialog.closeLast()
                },
                onCancel: () => {
                  UIDialog.closeLast()
                }
              })
            })
        }
        .width($r('app.string.width_percent_full'))
        .justifyContent(FlexAlign.SpaceBetween)
      }
    }
  }

  @Builder serviceMenuArea() {
    ContainerColumn({ bottomGap: false }) {
      Column() {
        Text('常用服务')
          .fontSize(18)
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Bold)
          .margin({ top: $r('app.string.space_m'), bottom: $r('app.string.space_xs') })
        SettingCard({
          list: this.vm.list,
        })
      }
      .margin({ top: 4 })
      .height('148')
      .width($r('app.string.width_percent_full'))
      .alignItems(HorizontalAlign.Start)
    }
  }

  @Builder upgradeDialogBuilder() {
    Column({ space: 16 }) {
      Text('设置用户名和密码以升级账号，升级后可启用云同步功能。')
        .fontSize(14)
        .fontColor($r('app.color.font_color_level1'))
        .textAlign(TextAlign.Center)
        .width('100%')
        .margin({ bottom: 8 })

      TextInput({ placeholder: '用户名（3-30字符）', text: this.upgradeUsername })
        .width('100%')
        .height(44)
        .backgroundColor($r('sys.color.comp_background_tertiary'))
        .borderRadius(8)
        .onChange((value: string) => {
          this.upgradeUsername = value
        })

      TextInput({ placeholder: '密码（至少6字符）', text: this.upgradePassword })
        .width('100%')
        .height(44)
        .backgroundColor($r('sys.color.comp_background_tertiary'))
        .borderRadius(8)
        .type(InputType.Password)
        .onChange((value: string) => {
          this.upgradePassword = value
        })
    }
    .width('100%')
    .padding(16)
  }

  }

@Extend(Image)
function commonIconStyle() {
  .draggable(false)
  .height(16)
  .width(16)
  .fillColor($r('app.color.icon_color_level2'));
}

@Extend(Text)
function commonLabelStyle() {
  .fontSize(12)
  .maxLines(1)
  .textOverflow({ overflow: TextOverflow.Ellipsis })
  .fontColor($r('app.color.font_color_level1'));
}