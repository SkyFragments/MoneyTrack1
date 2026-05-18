import { Want } from '@kit.AbilityKit';
import { emitter } from '@kit.BasicServicesKit';
import { formBindingData, FormExtensionAbility, formInfo } from '@kit.FormKit';
import { WindowUtil } from 'commonlib';
import { WidgetUtil } from '../common/WidgetUtil';

export default class EntryFormAbility extends FormExtensionAbility {
  public onAddForm(want: Want) {
    let formId = want.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string | undefined;
    if (formId) {
      WidgetUtil.addFormId(formId, this.context);
      WidgetUtil.publishFormId(formId, false);
    }
    return formBindingData.createFormBindingData('');
  }

  public onUpdateForm() {
    try {
      emitter.emit({ eventId: 1 });
    } catch (error) {
      WindowUtil.dealAllError(error);
    }
  }

  public onRemoveForm(formId: string) {
    WidgetUtil.delFormId(formId, this.context);
    WidgetUtil.publishFormId(formId, true);
  }
}
