import { BillDetail } from 'bill_card';
import { CommonHeader, RouterModule } from 'commonlib';
import { BillDetailVM } from '../viewmodels/BillDetailVM';

@Builder
export function billDetailPageBuilder() {
  BillDetailPage();
}

@Entry
@ComponentV2
struct BillDetailPage {
  vm: BillDetailVM = new BillDetailVM();

  build() {
    NavDestination() {
      CommonHeader({ title: '账单详情' });
      // 账单信息
      Column() {
        if (this.vm.bill) {
          BillDetail({
            bill:this.vm.bill,
            handleDelete:()=> {
              this.vm.deleteBill();
            },
            handleEdit:()=> {
              this.vm.editBill();
            },
          })
            .width('100%')
            .constraintSize({ maxWidth: 805 });
        }
      }
    }
    .hideTitleBar(true)
    .padding($r('app.string.space_l'))
    .backgroundColor($r('app.color.system_color_background_auxiliary'))
    .onBackPressed(()=> {
      RouterModule.pop(1);
      return true;
    })
    .onReady(() => {
      this.vm.initData();
    });
  }
}