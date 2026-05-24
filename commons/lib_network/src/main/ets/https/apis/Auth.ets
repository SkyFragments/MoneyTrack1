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
  username: string;
  password: string;
}

interface RegisterParams {
  username: string;
  password: string;
}

interface RefreshParams {
  refreshToken: string;
}

interface HuaweiLoginParams {
  openId: string;
  email?: string;
}

interface PhoneLoginParams {
  phoneNumber: string;
  code: string;
}

interface PhoneSendParams {
  phoneNumber: string;
}

interface UpgradeParams {
  username: string;
  password: string;
}

class AuthApis {
  public me(): Promise<BaseResponse<MeResponseData>> {
    return request.get(RequestUrlMap.AUTH_ME)
  }

  public login(params: LoginParams): Promise<BaseResponse<LoginResponseData>> {
    return request.post(RequestUrlMap.AUTH_LOGIN, params)
  }

  public register(params: RegisterParams): Promise<BaseResponse<LoginResponseData>> {
    return request.post(RequestUrlMap.AUTH_REGISTER, params)
  }

  public refresh(params: RefreshParams): Promise<BaseResponse<TokenRefreshResponseData>> {
    return request.post(RequestUrlMap.AUTH_REFRESH, params)
  }

  public huaweiLogin(params: HuaweiLoginParams): Promise<BaseResponse<HuaweiLoginData>> {
    return request.post(RequestUrlMap.AUTH_HUAWEI_LOGIN, params)
  }

  public upgrade(params: UpgradeParams): Promise<BaseResponse<LoginResponseData>> {
    return request.post(RequestUrlMap.AUTH_UPGRADE, params)
  }

  public phoneLoginSend(params: PhoneSendParams): Promise<BaseResponse> {
    return request.post(RequestUrlMap.AUTH_PHONE_SEND, params)
  }

  public phoneLogin(params: PhoneLoginParams): Promise<BaseResponse<LoginResponseData>> {
    return request.post(RequestUrlMap.AUTH_PHONE_LOGIN, params)
  }
}

const instance = new AuthApis();

export { instance as AuthApis };
