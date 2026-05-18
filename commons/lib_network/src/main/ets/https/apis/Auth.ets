import { BaseResponse } from '../../types/responses/BaseResponse';
import { RequestUrlMap } from '../../constants/Enums';
import request from '../Request'

class AuthApis {
  /**
   * Get current user info
   */
  public me(): Promise<BaseResponse> {
    return request.get(RequestUrlMap.AUTH_ME)
  }

  /**
   * Login
   */
  public login(params?: object): Promise<BaseResponse> {
    return request.post(RequestUrlMap.AUTH_LOGIN, params)
  }

  /**
   * Register
   */
  public register(params?: object): Promise<BaseResponse> {
    return request.post(RequestUrlMap.AUTH_REGISTER, params)
  }

  /**
   * Refresh token
   */
  public refresh(params?: object): Promise<BaseResponse> {
    return request.post(RequestUrlMap.AUTH_REFRESH, params)
  }
}

const instance = new AuthApis();

export { instance as AuthApis };