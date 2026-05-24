import { BaseResponse } from '../../types/responses/BaseResponse';
import { RequestUrlMap } from '../../constants/Enums';
import request from '../Request'
import { AuthCache } from 'commonlib';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'Sync';
const DOMAIN = 0x0000;

// 定义明确的接口，不用 object[]
interface SyncPullResult {
  accounts: object[];
  transactions: object[];
  assets: object[];
  budgets: object[];
  categories: object[];
  serverTime: number | string;
}

class SyncApis {
  public pull(params?: object): Promise<BaseResponse<SyncPullResult>> {
    if (AuthCache.getUserType() === 'guest') {
      // Local-only mode: skip network sync
      hilog.info(DOMAIN, TAG, 'Guest mode - skipping cloud sync pull');
      return Promise.resolve({ code: 0, data: { accounts: [], transactions: [], assets: [], budgets: [], categories: [], serverTime: '' } } as BaseResponse<SyncPullResult>);
    }
    return request.get(RequestUrlMap.SYNC_PULL, { params })
  }

  public push(data?: object): Promise<BaseResponse<{synced: number}>> {
    if (AuthCache.getUserType() === 'guest') {
      // Local-only mode: skip network sync
      hilog.info(DOMAIN, TAG, 'Guest mode - skipping cloud sync push');
      return Promise.resolve({ code: 0, data: { synced: 0 } } as BaseResponse<{synced: number}>);
    }
    return request.post(RequestUrlMap.SYNC_PUSH, data)
  }
}

const instance = new SyncApis();

export { instance as SyncApis };
