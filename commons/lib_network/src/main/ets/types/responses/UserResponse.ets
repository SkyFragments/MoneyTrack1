import { GenderType } from 'collect_personal_info';
import { BaseResponse } from './BaseResponse';

export interface UserLoginReq {
  phoneNumbers?: string
  verifyCode?: string
  unionID?: string
  authorizationCode?: string
}

export interface UpdateUserInfoReq {
  type: string // avatar nickname gender date name phone
  value: ResourceStr | GenderType | Date
}

export interface MembershipInfo {
  startDate: string // YYYY-MM-DD
  expireDate: string // YYYY-MM-DD
  isSubscribed: boolean
}

export interface MembershipInfoResp extends BaseResponse {
  data:MembershipInfo
}
