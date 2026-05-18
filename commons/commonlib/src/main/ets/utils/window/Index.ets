import { display, UIContext, window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { contextUtil } from '../ContextUtil';
import { Logger } from '../logger/Index';

const TAG = '[WindowUtil]';

@ObservedV2
export class AvoidAreaSize {
  @Trace top: number = 0;
  @Trace bottom: number = 0;
}

@ObservedV2
export class WindowUtil {
  private static _currentWindow: window.Window;

  public static get currentWindow() {
    return WindowUtil._currentWindow;
  }

  private static _display: display.Display;

  public static get display(): display.Display {
    return WindowUtil._display;
  }

  private static _context: Context;

  public static get context(): Context {
    return WindowUtil._context;
  }

  private static _uiContext: UIContext;

  public static get uiContext(): UIContext {
    return WindowUtil._uiContext;
  }

  public static updateDisplay() {
    try {
      WindowUtil._display = display.getDefaultDisplaySync();
    } catch (error) {
      WindowUtil.dealAllError(error);
    }
  }

  public static async initWindowUtil() {
    await WindowUtil._getCurrentWindow();
    WindowUtil.updateDisplay();
    WindowUtil._getContext();
  }

  public static setFullWindow(isFull: boolean = true) {
    if (WindowUtil._currentWindow) {
      WindowUtil._currentWindow
        .setWindowLayoutFullScreen(isFull)
        .then(() => {
          Logger.info(TAG, 'set full window success');
        })
        .catch((error: BusinessError) => {
          WindowUtil.dealAllError(error);
        });
    }
  }

  private static _getContext() {
    if (WindowUtil._currentWindow) {
      WindowUtil._context = contextUtil.getContext()!;
      try {
        WindowUtil._uiContext = WindowUtil._currentWindow.getUIContext();
      } catch (error) {
        WindowUtil.dealAllError(error);
      }
    }
  }

  private static async _getCurrentWindow() {
    return window
      .getLastWindow(contextUtil.getContext())
      .then((win) => {
        WindowUtil._currentWindow = win;
      })
      .catch((error: BusinessError) => {
        WindowUtil.dealAllError(error);
      });
  }

  public static dealAllError(error: BusinessError): void {
    Logger.error(TAG, `errorCode: ${error.code}, errorMsg: ${error.message}`);
  }
}
