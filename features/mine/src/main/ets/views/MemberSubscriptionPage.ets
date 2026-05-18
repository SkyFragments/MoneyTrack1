import { iap } from '@kit.IAPKit';
import { ToastDialog } from '@hw-agconnect/ui-toast';
import { BreakpointSystem, RouterModule } from  'commonlib';
import { MembershipInfo, UserApis } from 'lib_network';
import { FinishStatus, MemberList, MemberParams, MemberSheetUtils, MemberShipPage } from 'membership';
import { PRIVACY_CONTENT, PRODUCTS_INFO } from '../common/Constants';

@Builder
export function buildMemberSubscriptionPage() {
  MemberSubscriptionPage()
}

@ComponentV2
export struct MemberSubscriptionPage {
  @Local membershipInfo: MembershipInfo | undefined;

  @Computed
  get expireDate() {
    return this.membershipInfo?.expireDate ?? ''
  }

  aboutToAppear(): void {
    if (BreakpointSystem.isTablet) {
      RouterModule.pop()
      MemberSheetUtils.open({
        themeColor: $r('app.color.v_diamond_theme'),
        linearColors: [['#FFFFFF', 0.0], ['#D3B685', 1.0]],
        isSheet: true,
        lastPurchaseProductExpireTime: this.expireDate,
        productsInfo: PRODUCTS_INFO,
        privacyContent: PRIVACY_CONTENT,
        subscribeCallBack: (params): Promise<void> => this.subscribeEvent(params),
        queryExpireTime: (): Promise<void> => this.getMembershipInfo(),
        ownedMemberCallBack: (list): Promise<void> => this.ownedMemberEvent(list),
        btnFontColor: '#E5000000'
      }, this.getUIContext());
    }
  }

  build() {
    NavDestination() {
      MemberShipPage({
        routerModule: RouterModule.getStack(),
        themeColor: $r('app.color.v_diamond_theme'),
        linearColors: [['#FFFFFF', 0.0], ['#D3B685', 1.0]],
        isSheet: false,
        lastPurchaseProductExpireTime: this.expireDate,
        productsInfo: PRODUCTS_INFO,
        privacyContent: PRIVACY_CONTENT,
        subscribeCallBack: (params): Promise<void> => this.subscribeEvent(params),
        queryExpireTime: (): Promise<void> => this.getMembershipInfo(),
        ownedMemberCallBack: (list): Promise<void> => this.ownedMemberEvent(list),
      });
    }.hideTitleBar(true)
  }

  async subscribeEvent(params: MemberParams) {
    if (params.type === iap.ProductType.NONRENEWABLE && params.status === FinishStatus.FINISHED) {
      const res = await UserApis.subscribeMembership()
      if (res.code === 0) {
        ToastDialog.showToast({ message: '会员订阅成功！' })
        this.getMembershipInfo()
      }
    }
  };

  async ownedMemberEvent(list: MemberList) {
    if (!this.membershipInfo) {
      await this.getMembershipInfo()
    }
    if (list.nonRenewList.length && !this.membershipInfo?.isSubscribed) {
      UserApis.subscribeMembership()
    }
  };

  async getMembershipInfo() {
    const res = await UserApis.getMembershipInfo()
    if (res.code === 0) {
      this.membershipInfo = res.data;
    }
  }
}