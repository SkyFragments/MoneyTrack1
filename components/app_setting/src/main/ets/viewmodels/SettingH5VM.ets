import { webview } from '@kit.ArkWeb';
import { Logger } from 'module_ui_base';
import { LOG_TAG } from '../constants/CommonConstants';
import { BaseViewModel } from '../models/BaseViewModel';
import { SettingPageEnum } from '../types/SettingType';

@ObservedV2
export class SettingH5VM extends BaseViewModel {
  // H5内容或者地址
  @Trace content: string = '';
  @Trace webViewController: webview.WebviewController =
    new webview.WebviewController();

  getParams() {
    const params = this.configInfo.pathStack.getParamByName(
      SettingPageEnum.SETTING_AGREEMENT,
    ) as string[];
    if (params.length && params[params.length - 1]) {
      this.content = params[params.length - 1];
    }
  }

  onControllerAttached() {
    try {
      this.webViewController.loadUrl(this.content);
    } catch (error) {
      Logger.error(LOG_TAG, 'load url failed. error: ' + JSON.stringify(error))
    }
  }

  @Computed
  get getDefaultFontSize() {
    if (this.fontModel.followSystem) {
      return 16;
    }
    return 16 * this.fontModel.fontSizeRatio;
  }

  @Computed
  get getTextZoomRatio() {
    if (this.fontModel.followSystem) {
      return 100 * this.fontModel.sysFontSizeScale;
    }
    return 100;
  }

  isUrl(content: string) {
    return content.startsWith('http://') || content.startsWith('https://');
  }
}
