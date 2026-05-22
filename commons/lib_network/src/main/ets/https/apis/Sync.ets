import { BaseResponse } from '../../types/responses/BaseResponse';
import { RequestUrlMap } from '../../constants/Enums';
import request from '../Request'

// 定义明确的接口，不用 object[]
interface SyncPullResult {
  accounts: object[];
  transactions: object[];
  assets: object[];
  budgets: object[];
  categories: object[];
  serverTime: number;
}

class SyncApis {
  public pull(params?: object): Promise<BaseResponse<SyncPullResult>> {
    return request.get(RequestUrlMap.SYNC_PULL, { params })
  }

  public push(data?: object): Promise<BaseResponse> {
    return request.post(RequestUrlMap.SYNC_PUSH, data)
  }
}

const instance = new SyncApis();

export { instance as SyncApis };
