import { BaseResponse } from '../../types/responses/BaseResponse';
import { RequestUrlMap } from '../../constants/Enums';
import request from '../Request'

interface UserIdInfo {
  id: string;
}

interface HuaweiLoginData {
  user?: UserIdInfo;
  accessToken: string;
  refreshToken: string;
}

interface LoginResponseData {
  user?: UserIdInfo;
  accessToken: string;
  refreshToken: string;
}

interface TokenRefreshResponseData {
  accessToken: string;
  refreshToken: string;
}

interface MeResponseData {
  id: string;
  email: string;
  createdAt: string;
}

interface LoginParams {
  email: string;
  password: string;
}

interface RegisterParams {
  email: string;
  password: string;
}

interface RefreshParams {
  refreshToken: string;
}

interface HuaweiLoginParams {
  openId: string;
  email?: string;
}

class AuthApis {
  public me(): Promise<BaseResponse<MeResponseData>> {
    return request.get(RequestUrlMap.AUTH_ME)
  }

  public login(params: LoginParams): Promise<BaseResponse<LoginResponseData>> {
    return request.post(RequestUrlMap.AUTH_LOGIN, params)
  }

  public register(params: RegisterParams): Promise<BaseResponse> {
    return request.post(RequestUrlMap.AUTH_REGISTER, params)
  }

  public refresh(params: RefreshParams): Promise<BaseResponse<TokenRefreshResponseData>> {
    return request.post(RequestUrlMap.AUTH_REFRESH, params)
  }

  public huaweiLogin(params: HuaweiLoginParams): Promise<BaseResponse<HuaweiLoginData>> {
    return request.post(RequestUrlMap.AUTH_HUAWEI_LOGIN, params)
  }
}

const instance = new AuthApis();

export { instance as AuthApis };
