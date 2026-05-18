import { BillManageSheet, billManageSheetBuilder } from '../components/BillManageSheet';

@Entry
@ComponentV2
struct BillManageSheetDisplay {
  @Local showCreateSheet: boolean = false;
  @Local stack: NavPathStack = new NavPathStack();

  @Builder
  pageMap(url: string) {
    if (url === 'useComponent') {
      UseComponent();
    }
  }

  build() {
    Navigation(this.stack) {
      Column({ space: 24 }) {
        Text('使用方式1：直接使用组件嵌入页面');
        Button('打开')
          .onClick(() => {
            this.stack.pushPath({ name: 'useComponent' });
          });
        Text('使用方式2：使用bindSheet拉起半模态弹框使用');
        Button('打开')
          .onClick(() => {
            this.showCreateSheet = !this.showCreateSheet;
          })
          .bindSheet($$this.showCreateSheet,
            billManageSheetBuilder({}), {
              title: { title: '选择资产类型' },
              detents: [SheetSize.FIT_CONTENT],
            });
      };

    }
    .navDestination(this.pageMap);
  }
}


@ComponentV2
struct UseComponent {
  build() {
    NavDestination() {
      BillManageSheet().height('100%')
    }
    .title('创建账单');
  }
}
