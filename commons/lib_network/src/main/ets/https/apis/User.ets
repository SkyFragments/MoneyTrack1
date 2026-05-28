import { UserLoginReq, UpdateUserInfoReq, MembershipInfoResp } from '../../types/responses/UserResponse';
import { BaseResponse } from '../../types/responses/BaseResponse';
import { RequestUrlMap } from '../../constants/Enums';
import request from '../Request'

class UserApis {
  /**
   * 用户登录
   */
  public login(params?: UserLoginReq): Promise<BaseResponse> {
    const reqParams: Record<string, string> | undefined = params as Record<string, string>;
    if (reqParams) {
      return request.getWithParams<BaseResponse>(RequestUrlMap.USER_LOGIN, reqParams);
    }
    return request.get<BaseResponse>(RequestUrlMap.USER_LOGIN);
  }

  /**
   * 用户登出
   */
  public logout(): Promise<BaseResponse> {
    return request.get<BaseResponse>(RequestUrlMap.USER_LOGOUT)
  }

  /**
   * 修改用户信息
   */
  public updateUserInfo(data: UpdateUserInfoReq): Promise<BaseResponse> {
    return request.put<BaseResponse>(RequestUrlMap.USER_INFO, data)
  }
  /**
   * 开通/续费年卡会员
   */
  public subscribeMembership(): Promise<BaseResponse> {
    return request.post<BaseResponse>(RequestUrlMap.USER_MEMBERSHIP)
  }
  /**
   * 查询会员信息
   */
  public getMembershipInfo(): Promise<MembershipInfoResp> {
    return request.get<MembershipInfoResp>(RequestUrlMap.USER_MEMBERSHIP)
  }
}

const instance = new UserApis();

export { instance as UserApis };