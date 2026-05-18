import { AppStorageV2 } from '@kit.ArkUI';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { FunctionalButton, functionalButtonComponentManager } from '@kit.ScenarioFusionKit';
import { Constants } from '../common/Constant';
import { ConfigInfo } from '../common/ConfigModel';
import { ERROR_MSG_MAP } from '../common/ErrorMsgMap';
import { Logger } from 'module_ui_base';

const TAG = '[ChooseAvatar]';

@ComponentV2
export struct ChooseAvatar {
  /**
   * 传入的头像地址
   */
  @Param url: ResourceStr = '';
  /**
   * 头像高度
   */
  @Param avatarH: Length = 48;
  /**
   * 选择头像的回调
   */
  @Event onChooseAvatar: (url: string) => void;
  @Local configInfo: ConfigInfo = AppStorageV2.connect(ConfigInfo, () => new ConfigInfo())!;

  build() {
    FunctionalButton({
      params: {
        openType: functionalButtonComponentManager.OpenType.CHOOSE_AVATAR,
        label: '',
        styleOption: {
          styleConfig: new functionalButtonComponentManager.ButtonConfig()
            .type(ButtonType.Normal)
            .backgroundImage(this.url)
            .backgroundImageSize(ImageSize.Cover)
            .backgroundColor(Color.Transparent)
            .width(this.avatarH)
            .height(this.avatarH)
            .borderRadius(Constants.HALF_PERCENT),
        },
      },
      controller: new functionalButtonComponentManager.FunctionalButtonController().onChooseAvatar((err, data) => {
        if (err) {
          this.handleError(err);
          return;
        }
        let url = data.avatarUri!;
        let avatarFile: fs.File | null = null;
        try {
          avatarFile = fs.openSync(url, fs.OpenMode.READ_ONLY);
          let newPath: string =
            this.getUIContext().getHostContext()?.cacheDir + `/${util.generateRandomUUID(false)}.png`;
          fs.copyFileSync(avatarFile.fd, newPath);
          url = 'file://' + newPath;
        } catch (err) {
          Logger.error(TAG, 'handle avatar file failed, error: ' + JSON.stringify(err));
        } finally {
          if (avatarFile) {
            fs.closeSync(avatarFile);
          }
        }

        this.onChooseAvatar(url);
      }),
    })
  }

  handleError(error: BusinessError) {
    Logger.error(TAG, 'onChooseAvatar failed, error: ' + JSON.stringify(error));
    const errorMsg: string = ERROR_MSG_MAP[error.code] ?? '';
    if (errorMsg) {
      this.getUIContext().getPromptAction().showDialog({
        title: '温馨提示',
        message: errorMsg,
        buttons: [
          { text: '确定', color: this.configInfo.themeColor },
        ],
      }).catch((error: BusinessError) => {
        Logger.error(TAG, 'open dialog failed, error: ' + JSON.stringify(error));
      })
    }
  }
}
