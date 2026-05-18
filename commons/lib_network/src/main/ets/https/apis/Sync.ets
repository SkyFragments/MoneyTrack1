import { BaseResponse } from '../../types/responses/BaseResponse';
import { RequestUrlMap } from '../../constants/Enums';
import request from '../Request'

class SyncApis {
  /**
   * Pull sync data from server
   */
  public pull(params?: object): Promise<BaseResponse> {
    return request.get(RequestUrlMap.SYNC_PULL, { params })
  }

  /**
   * Push sync data to server
   */
  public push(data?: object): Promise<BaseResponse> {
    return request.post(RequestUrlMap.SYNC_PUSH, data)
  }
}

const instance = new SyncApis();

export { instance as SyncApis };