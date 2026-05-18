import { SettingCard } from 'app_setting';
import { CommonHeader, ContainerColumn, iData, RouterMap, RouterModule } from 'commonlib';
import { BillInfoCard } from '../components/BillInfoCard';
import { MineVM } from '../viewmodels/MineVM';

@ComponentV2
export struct MineView {
  vm: MineVM = new MineVM();

  aboutToAppear(): void {
    // 加载记账统计信息
    this.vm.loadBillInfo();
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