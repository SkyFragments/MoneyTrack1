import { window } from '@kit.ArkUI';
import { contextUtil, WindowUtil } from 'commonlib';

@ComponentV2
export struct FloatingButton {
  // 图标大小
  @Param iconSize: Length = 72;
  // 点击事件
  @Event handleClick: () => void;
  //状态栏高度
  @Local statusHeight: number = 0;
  //手机底部规避区域高度
  @Local bottomAvoidAreaHeight: number = 0;
  //当前悬浮按钮距离窗口左边距离
  @Local curLeft: number = 0;
  //当前悬浮按钮距离窗口顶部距离
  @Local curTop: number = 0;
  // 按钮距离屏幕左边的最大距离
  @Local maxLeft: number = 0;
  // 按钮距离屏幕顶部的最大距离
  @Local maxTop: number = 0;
  // 窗口
  @Local
  windowClass: window.Window | undefined = undefined;
  //开始移动那一刻悬浮按钮距离窗口左边距离
  private _startLeft: number = 0;
  //开始移动那一刻悬浮按钮距离窗口顶部距离
  private _startTop: number = 0;
  //开始移动触摸点x坐标，相对窗口左上角
  private _startX: number = 0;
  //开始移动触摸点y坐标，相对窗口左上角
  private _startY: number = 0;
  //悬浮按钮半径，单位vp
  private _radius: number = 25;
  //窗口宽度
  private _winWidth: number = 0;
  //窗口高度
  private _winHeight: number = 0;

  async aboutToAppear() {
    try {
      this.windowClass = await window.getLastWindow(contextUtil.getContext()!);
      this.getWindowInfo();
      if (this.windowClass) {
        this.windowClass.on('windowSizeChange', () => {
          this.getWindowInfo();
        });
      }
    } catch (err) {
      this.curLeft = 200;
      this.curTop = 400;
    }
  }

  aboutToDisappear(): void {
    this.windowClass?.off('windowSizeChange', () => {
      this.getWindowInfo();
    });
  }

  build() {
    Column() {
      Image($r('app.media.ic_create_bill')).width(this.iconSize);
    }
    .width(this._radius * 3)
    .height(this._radius * 3)
    .justifyContent(FlexAlign.Center)
    .borderRadius(this._radius)
    .zIndex(99)
    .position({
      y: this.curTop,
      x: this.curLeft,
    })
    .onTouch((event: TouchEvent) => {
      this.handleTouch(event);
    })
    .onClick(() => {
      this.handleClick?.();
    });
  }

  //获取窗口尺寸信息
  async getWindowInfo() {
    if (!this.windowClass) {
      return;
    }
    try {
      const uiContext = contextUtil.getUiContext();
      //状态栏高度
      this.statusHeight =
        uiContext?.px2vp(this.windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height) ?? 0;
      //获取手机底部规避区域高度，额外避让底部tab栏
      this.bottomAvoidAreaHeight =
        (uiContext?.px2vp(this.windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR)
          .bottomRect
          .height) ?? 0) + 70;

      //获取窗口宽高
      let windowProperties = this.windowClass.getWindowProperties();
      this._winWidth = uiContext?.px2vp(windowProperties.windowRect.width) ?? 0;
      this._winHeight = uiContext?.px2vp(windowProperties.windowRect.height) ?? 0;
    } catch (error) {
      WindowUtil.dealAllError(error);
    }

    //设置初始位置位于屏幕右下角，演示设置可根据实际调整
    const minRight = Math.max(24, this._winWidth * 0.20);
    const minBottom = Math.max(100, this._winHeight * 0.30);
    this.maxLeft = this._winWidth - minRight;
    this.maxTop = this._winHeight - minBottom;
    this.curLeft = this.maxLeft;
    this.curTop = this.maxTop;

  }

  handleTouch(event: TouchEvent) {
    //手指按下记录初始触摸点坐标、悬浮按钮位置
    if (event.type === TouchType.Down) {
      this._startX = event.touches[0].windowX;
      this._startY = event.touches[0].windowY;
      this._startLeft = this.curLeft;
      this._startTop = this.curTop;
    } else if (event.type === TouchType.Move) {
      let touch = event.touches[0];
      //计算悬浮球与左边距离（x坐标）， 当前悬浮球距离左边=开始位置(x轴)+（当前触摸点x坐标-开始移动触摸点x坐标）
      let curLeft = this._startLeft + (touch.windowX - this._startX);
      //限制悬浮球移动范围
      curLeft = Math.max(0, curLeft);
      this.curLeft = Math.min(this.maxLeft, curLeft);
      let curTop = this._startTop + (touch.windowY - this._startY);
      curTop = Math.max(0, curTop);
      this.curTop = Math.min(this.maxTop, curTop);
    }
  }
}
