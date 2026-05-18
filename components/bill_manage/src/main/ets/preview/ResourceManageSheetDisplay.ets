import { ResourceManageSheet, resourceManageSheetBuilder } from '../components/ResourceManageSheet';

@Entry
@ComponentV2
struct ResourceManageSheetDisplay {
  @Local showSheet: boolean = false;
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
            this.showSheet = !this.showSheet;
          })
          .bindSheet($$this.showSheet,
            resourceManageSheetBuilder({}), {
              title: { title: '分类管理' },
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
      ResourceManageSheet();
    }
    .title('创建账单');
  }
}
