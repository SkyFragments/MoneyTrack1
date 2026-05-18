import dayjs from 'dayjs';

const storageMiddle = new LocalStorage();

class Temp {
  title: string = '';
  amount: number = 0;
  rectColor?: ResourceColor = $r('app.color.system_theme_color');
}

@Entry(storageMiddle)
@Component
struct MiddleCard {
  @LocalStorageProp('date') date: Date = new Date();
  @LocalStorageProp('expense') expense: number = 0;
  @LocalStorageProp('income') income: number = 0;

  build() {
    Column() {
      Text(dayjs(this.date).format('YYYY年MM月'))
        .fontSize($r('app.string.font_size_14'))
        .fontColor($r('app.color.font_color_level1'))
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 12 });
      Row() {
        this.amountBuilder({
          title: '支出',
          amount: this.expense,
          rectColor: $r('app.color.system_theme_color'),
        });
        this.amountBuilder({
          title: '收入',
          amount: this.income,
          rectColor: $r('app.color.system_theme_color2'),
        });
      }
      .width('100%');

      Blank();

      Flex() {
        Button('查看资产')
          .backgroundColor($r('app.color.system_color_background_grey_level2'))
          .fontColor($r('app.color.system_theme_color'))
          .fontSize($r('sys.float.Body_M'))
          .height(36)
          .width('100%')
          .onClick(() => {
            postCardAction(this, {
              action: 'router',
              abilityName: 'EntryAbility',
              params: {
                cardType: 'middle',
                message: 'assets',
              },
            });
          });

        Blank().width(24);

        Button('记一笔')
          .backgroundColor($r('app.color.system_theme_color'))
          .fontSize($r('sys.float.Body_M'))
          .height(36)
          .width('100%')
          .onClick(() => {
            postCardAction(this, {
              action: 'router',
              abilityName: 'EntryAbility',
              params: {
                cardType: 'middle',
                message: 'home',
              },
            });
          });
      };

    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(12);
  }

  @Builder
  amountBuilder($$: Temp) {
    Column() {
      Row() {
        Rect()
          .width(4)
          .height(12)
          .margin({ right: 4 })
          .fill($$.rectColor);
        Text($$.title)
          .fontSize($r('app.string.font_size_12'))
          .fontColor($r('app.color.font_color_level2'));
      }
      .margin({ bottom: 4 });

      Text($$.amount.toFixed(2))
        .fontWeight(FontWeight.Medium)
        .fontSize($r('app.string.font_size_18'))
        .fontColor($r('app.color.font_color_level1'))
        .margin({ left: 8 });
    }
    .width('50%')
    .alignItems(HorizontalAlign.Start);
  }
}