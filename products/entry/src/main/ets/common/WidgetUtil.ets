import { preferences } from '@kit.ArkData';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';
import { formBindingData, formProvider } from '@kit.FormKit';
import { AmountSummary, BillProcessingModel } from 'bill_data_processing';
import { contextUtil, Logger, WindowUtil } from 'commonlib';

const TAG = '[WidgetUtil]';

export class WidgetUtil {
  private static readonly _fileName: string = 'accounting_form_id_file';
  private static readonly _formIdKey: string = 'accounting_form_id_key';
  private static readonly _formIdEventName: string = 'form_id_event_name';
  private static _billProcessing: BillProcessingModel =
    new BillProcessingModel();

  public static getFormIds(ctx: Context) {
    try {
      const store = preferences.getPreferencesSync(ctx, { name: WidgetUtil._fileName });
      return store.getSync(WidgetUtil._formIdKey, []) as string[];
    } catch (error) {
      WindowUtil.dealAllError(error);
      return [];
    }
  }

  public static async addFormId(formId: string, cxt: Context) {
    const list = WidgetUtil.getFormIds(cxt);
    if (!list.some((id) => id === formId)) {
      list.push(formId);
      try {
        const store = preferences.getPreferencesSync(cxt, { name: WidgetUtil._fileName });
        store.putSync(WidgetUtil._formIdKey, list);
        await store.flush();
      } catch (error) {
        WindowUtil.dealAllError(error);
      }
    }
  }

  public static async delFormId(formId: string, cxt: Context) {
    const list = WidgetUtil.getFormIds(cxt);
    const index = list.findIndex((id) => id === formId);
    if (index !== -1) {
      list.splice(index, 1);
      try {
        const store = preferences.getPreferencesSync(cxt, { name: WidgetUtil._fileName });
        store.putSync(WidgetUtil._formIdKey, list);
        await store.flush();
      } catch (error) {
        WindowUtil.dealAllError(error);
      }
    }
  }

  // 发布公共事件跨进程传递卡片id
  public static publishFormId(formId: string, isDelete: boolean) {
    try {
      commonEventManager.publish(
        WidgetUtil._formIdEventName,
        { data: formId, parameters: { isDelete } },
        (err: BusinessError) => {
          if (err) {
            Logger.error(
              TAG,
              `Failed to publish common event. Code is ${err.code}, message is ${err.message}`,
            );
          } else {
            Logger.info(TAG, 'Succeeded in publishing common event.');
          }
        },
      );
    } catch (error) {
      WindowUtil.dealAllError(error);
    }
  }

  // 订阅获取卡片id
  public static async subscribeFormId(ctx: Context) {
    let subscriber: commonEventManager.CommonEventSubscriber | undefined =
      undefined;
    let subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: [WidgetUtil._formIdEventName],
      publisherPermission: '',
    };
    try {
      commonEventManager.createSubscriber(subscribeInfo, (err1, data1) => {
        if (err1) {
          Logger.error(
            TAG,
            `Failed to create subscriber. Code is ${err1.code}, message is ${err1.message}`,
          );
          return;
        }
        subscriber = data1;
        // 订阅公共事件回调
        commonEventManager.subscribe(subscriber, async (err2, data2) => {
          if (err2) {
            Logger.error(
              TAG,
              `Failed to subscribe common event. Code is ${err2.code}, message is ${err2.message}`,
            );
            return;
          } else {
            if (data2.parameters?.isDelete) {
              WidgetUtil.delFormId(data2.data as string, ctx);
            } else {
              WidgetUtil.addFormId(data2.data as string, ctx);
              WidgetUtil.updateWidgetsWhenChange();
            }
            Logger.info(TAG, 'Succeeded in creating subscriber1.');
          }
        });
      });
    } catch (error) {
      WindowUtil.dealAllError(error);
    }
  }

  public static async updateWidgetsWhenChange() {
    await WidgetUtil._billProcessing.getBillReport();
    const summary: AmountSummary = {
      totalExpense: Number(WidgetUtil._billProcessing.totalExpense),
      totalIncome: Number(WidgetUtil._billProcessing.totalIncome),
    };
    WidgetUtil.getFormIds(contextUtil.getContext()!).forEach((id) => {
      const income = summary.totalIncome;
      const expense = summary.totalExpense;
      class TempForm {
        date: Date = new Date();
        income: number = 0;
        expense: number = 0;
      }
      const formData: TempForm = {
        date: new Date(),
        income,
        expense,
      };
      formProvider.updateForm(
        id,
        formBindingData.createFormBindingData(formData),
      ).catch((error: BusinessError) => {
        WindowUtil.dealAllError(error);
      });
    });
  }
}
