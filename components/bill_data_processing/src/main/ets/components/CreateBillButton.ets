import { BillManageUtil } from '../utils/BillManageUtil';
import { FloatingButton } from './FloatingButton';

@ComponentV2
export struct CreateBillButton {
  @Param @Require
  accountId: number;
  @Param
  assetId: number | undefined = undefined;
  @Event
  handleCreateSuccess: () => void;

  build() {
    FloatingButton({
      handleClick: () => {
        BillManageUtil.manageBill(undefined, this.assetId, this.accountId, this.handleCreateSuccess);
      },
    });
  }
}
