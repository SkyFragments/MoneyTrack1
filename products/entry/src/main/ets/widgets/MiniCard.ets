import dayjs from 'dayjs';

const storageMini = new LocalStorage();

@Entry(storageMini)
@Component
struct MiniCard {
  @LocalStorageProp('date') date: Date = new Date();
  @LocalStorageProp('expense') expense: number = 0;

  build() {
    Column() {
      Text(dayjs(this.date).format('YYYY年MM月'))
        .fontSize($r('app.string.font_size_12'))
        .fontColor($r('app.color.font_color_level1'))
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 12 });
      Row() {
        Rect()
          .width(4)
          .height(12)
          .margin({ right: 4 })
          .fill($r('app.color.system_theme_color'));
        Text('支出')
          .fontSize($r('app.string.font_size_10'))
          .fontColor($r('app.color.font_color_level2'));
      }
      .margin({ bottom: 4 });

      Text(this.expense.toFixed(2))
        .fontWeight(FontWeight.Medium)
        .fontSize($r('app.string.font_size_18'))
        .fontColor($r('app.color.font_color_level1'))
        .margin({ left: 8 });

      Blank();

      Button('记一笔')
        .backgroundColor($r('app.color.system_theme_color'))
        .fontSize($r('sys.float.Body_M'))
        .height(36)
        .width('100%')
        .onClick(()=> {
          postCardAction(this, {
            action: 'router',
            abilityName: 'EntryAbility',
            params: {
              cardType: 'mini',
              message: 'home',
            },
          });
        })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(12);
  }
}