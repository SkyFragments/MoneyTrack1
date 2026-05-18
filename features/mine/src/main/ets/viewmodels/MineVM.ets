import { SettingGroup, SettingItem, SettingType } from 'app_setting';
import { AccountingDB, BillInfo } from 'bill_data_processing';
import { RouterMap, RouterModule } from 'commonlib';
import { ServiceMenuItem } from '../common/Types';

@ObservedV2
export class MineVM {
  @Trace list: SettingItem[] = [
    new SettingItem()
      .setType(SettingType.ROUTER)
      .setLabel('意见反馈')
      .setIcon($r('app.media.ic_mine_feedback'))
      .setClickEvent(() => { RouterModule.push({ url: RouterMap.FEEDBACK })}),
    new SettingItem()
      .setType(SettingType.ROUTER)
      .setLabel('设置')
      .setIcon($r('app.media.ic_mine_setting'))
      .setClickEvent(() => { RouterModule.push({ url: RouterMap.SETTING })}),
  ];
  @Trace group: SettingGroup = new SettingGroup().setList(this.list)
  @Trace totalDays: number = 0;
  @Trace totalBills: number = 0;

  gridClick(v: ServiceMenuItem) {
    RouterModule.push({ url: v.routerName });
  }

  async loadBillInfo() {
    try {
      const billInfo: BillInfo = await AccountingDB.getBillStatistics();
      this.totalDays = billInfo.totalDays;
      this.totalBills = billInfo.totalBills;
    } catch (err) {
      console.error('loadBillInfo failed', err);
      this.totalDays = 0;
      this.totalBills = 0;
    }
  }
}