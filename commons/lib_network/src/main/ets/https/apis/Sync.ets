import { BaseResponse } from '../../types/responses/BaseResponse';
import { RequestUrlMap } from '../../constants/Enums';
import request from '../Request'
import { AuthCache } from 'commonlib';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'Sync';
const DOMAIN = 0x0000;

interface SyncPullResult {
  accounts: object[];
  transactions: object[];
  assets: object[];
  budgets: object[];
  categories: object[];
  serverTime: number | string;
}

interface SyncPushData {
  accounts?: object[];
  transactions?: object[];
  assets?: object[];
  budgets?: object[];
}

interface SyncCounts {
  accounts: number;
  transactions: number;
  assets: number;
  budgets: number;
}

interface SyncMapping {
  table: string;
  localId: string | number | null;
  serverId: number;
}

interface SyncedResult {
  counts: SyncCounts;
  mappings: SyncMapping[];
}

class SyncApis {
  public pull(params?: object): Promise<BaseResponse<SyncPullResult>> {
    if (AuthCache.getUserType() === 'guest') {
      hilog.info(DOMAIN, TAG, 'Guest mode - skipping cloud sync pull');
      return Promise.resolve({ code: 0, data: { accounts: [], transactions: [], assets: [], budgets: [], categories: [], serverTime: 0 } } as BaseResponse<SyncPullResult>);
    }
    const reqParams: Record<string, string> | undefined = params as Record<string, string>;
    if (reqParams) {
      return request.getWithParams<BaseResponse<SyncPullResult>>(RequestUrlMap.SYNC_PULL, reqParams);
    }
    return request.get<BaseResponse<SyncPullResult>>(RequestUrlMap.SYNC_PULL);
  }

  public push(data?: SyncPushData): Promise<BaseResponse<SyncedResult>> {
    if (AuthCache.getUserType() === 'guest') {
      hilog.info(DOMAIN, TAG, 'Guest mode - skipping cloud sync push');
      return Promise.resolve({ code: 0, data: { counts: { accounts: 0, transactions: 0, assets: 0, budgets: 0 }, mappings: [] } } as BaseResponse<SyncedResult>);
    }
    return request.post<BaseResponse<SyncedResult>>(RequestUrlMap.SYNC_PUSH, data)
      .then((res) => {
        if (res.code !== 0) {
          hilog.error(DOMAIN, TAG, `push API error: code=${res.code}, msg=${res.msg}`);
        }
        return res;
      })
      .catch(() => {
        hilog.error(DOMAIN, TAG, `push network error`);
        return { code: -1, msg: '推送失败', data: undefined } as BaseResponse<SyncedResult>;
      });
  }
}

const instance = new SyncApis();

export { instance as SyncApis };