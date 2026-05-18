import dayjs from 'dayjs';
import { CommonButton, CustomButtonType } from './CommonButton';

@ComponentV2
export struct CommonDayPicker {
  @Param
  initDay: string = '';
  @Local
  value: string[] = [''];
  @Local
  dayList: string[] = [];
  @Event
  handleConfirm: (dayStr: string) => void;
  @Event
  handleCancel: () => void;

  @Computed
  get pickerGroup() {
    return [this.dayList];
  }

  @Computed
  get selectedDay() {
    return this.value[0].split('日')[0];
  }

  aboutToAppear(): void {
    for (let i = 1; i <= 28; i++) {
      const dayStr = i < 10 ? `0${i}日` : `${i}日`;
      this.dayList.push(dayStr);
    }
    if (this.initDay) {
      let dayNum = parseInt(this.initDay);
      this.value[0] = `${dayNum}日`;
    } else {
      const cur = dayjs().date();
      const safeDay = cur > 28 ? 28 : cur;
      this.value[0] = `${safeDay}日`;
    }
  }

  build() {
    Column({ space: $r('app.string.space_m')}) {
      TextPicker({ range: this.pickerGroup, value: this.value })
        .onChange((value: string | string[]) => {
          if (Array.isArray(value)) {
            this.value[0] = value[0];
          } else {
            this.value[0] = value;
          }
        })
        .disappearTextStyle({
          font: { size: $r('app.string.font_size_14'), weight: FontWeight.Regular },
        })
        .textStyle({
          color: $r('app.color.font_color_level1'),
          font: { size: $r('app.string.font_size_16'), weight: FontWeight.Regular },
        })
        .selectedTextStyle({
          color: $r('app.color.font_color_level1'),
          font: {
            size: $r('app.string.font_size_20'),
            weight: FontWeight.Medium,
          },
        })
        .canLoop(false)
        .width('100%');
      Flex() {
        CommonButton({
          title: '取消',
          buttonType: CustomButtonType.SECONDARY,
          handleClick: () => {
            this.handleCancel?.();
          },
        });
        CommonButton({
          title: '确定',
          buttonType: CustomButtonType.PRIMARY,
          handleClick: () => {
            this.handleConfirm?.(this.selectedDay);
          },
        });
      }
    }
    .width($r('app.string.width_percent_full'))
    .padding({ left: $r('app.string.space_l'), right: $r('app.string.space_l') });
  }
}
