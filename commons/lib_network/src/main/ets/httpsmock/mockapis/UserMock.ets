import { PersistenceV2 } from '@kit.ArkUI';
import { AxiosRequestConfig, HttpStatusCode } from '@ohos/axios';
import dayjs from 'dayjs';
import AxiosMockAdapter from '@hw-agconnect/axios-mock-adapter';
import { GenderType } from 'collect_personal_info';
import { iData } from 'commonlib';
import {
  MembershipInfo,
  MembershipInfoResp,
  UpdateUserInfoReq,
  UserLoginReq
} from '../../types/responses/UserResponse';
import { BaseResponse } from '../../types/responses/BaseResponse';
import { RequestUrlMap } from '../../constants/Enums';

@ObservedV2
export class MembershipInfoModel implements MembershipInfo {
  startDate: string = ''
  expireDate: string = ''
  isSubscribed: boolean = false
}

export class UserMockApis {
  public start(adapter: AxiosMockAdapter) {
    // 用户登录
    adapter.onGet(RequestUrlMap.USER_LOGIN).reply((config: AxiosRequestConfig) => {
      const params = config.params as UserLoginReq
      iData.global.isLogin = true;
      iData.global.userInfo.reset();
      iData.global.userInfo.nickname = '华为用户';
      iData.global.userInfo.phone = '12345678900';
      iData.global.userInfo.anonymousPhone = params?.phoneNumbers ?? '123****8900'
      iData.global.userInfo.avatar = '';
      iData.global.userInfo.name = '';
      iData.global.userInfo.gender = GenderType.CONFIDENTIALITY;
      iData.global.userInfo.birth = new Date();
      const res: BaseResponse = {
        code: 0,
      }
      return [HttpStatusCode.Ok, res];
    })
    // 用户登出
    adapter.onGet(RequestUrlMap.USER_LOGOUT).reply(() => {
      iData.global.userInfo.reset();
      iData.global.isLogin = false;
      const res: BaseResponse = {
        code: 0,
      }
      return [HttpStatusCode.Ok, res];
    })
    // 更新用户信息
    adapter.onPut(RequestUrlMap.USER_INFO).reply((config: AxiosRequestConfig) => {
      const data = JSON.parse(config.data) as UpdateUserInfoReq
      switch (data.type) {
        case 'avatar':
          iData.global.userInfo.avatar = data.value as ResourceStr
          break;
        case 'nickname':
          iData.global.userInfo.nickname = data.value as string
          break;
        case 'phone':
          if (typeof data.value === 'string') {
            iData.global.userInfo.phone = data.value
            if ((data.value).length === 11) {
              iData.global.userInfo.anonymousPhone = data.value.slice(0, 3) + '****' + data.value.slice(7);
            }
          }
          break;
        case 'name':
          iData.global.userInfo.name = data.value as string
          break;
        case 'birth':
          iData.global.userInfo.birth = data.value as Date
          break;
        case 'gender':
          iData.global.userInfo.gender = data.value as GenderType
          break;
        default:
          break;
      }
      const res: BaseResponse = {
        code: 0,
      }
      return [HttpStatusCode.Ok, res];
    })

    // 开通/续费年卡会员
    adapter.onPost(RequestUrlMap.USER_MEMBERSHIP).reply(() => {
      const infoModel = PersistenceV2.connect(
        MembershipInfoModel,
        'membershipInfo',
        () => new MembershipInfoModel())!
      if (!infoModel.isSubscribed || (infoModel.isSubscribed && !infoModel.startDate)) {
        infoModel.isSubscribed = true
        const curDate = dayjs()
        infoModel.startDate = dayjs(curDate).format('YYYY-MM-DD')
        infoModel.expireDate = dayjs(curDate).set('year', curDate.year() + 1).format('YYYY-MM-DD')
      } else {
        const curDate: dayjs.Dayjs = dayjs(infoModel.expireDate)
        infoModel.expireDate =
          dayjs(new Date(infoModel.expireDate)).set('year', curDate.year() + 1).format('YYYY-MM-DD')
      }
      const res: BaseResponse = {
        code: 0,
      }
      return [HttpStatusCode.Ok, res]
    })

    // 查询会员信息
    adapter.onGet(RequestUrlMap.USER_MEMBERSHIP).reply(() => {
      const infoModel = PersistenceV2.connect(
        MembershipInfoModel,
        'membershipInfo',
        () => new MembershipInfoModel())!
      if (iData.global.userInfo.isMember && !infoModel.isSubscribed) {
        infoModel.isSubscribed = true
        const curDate = dayjs()
        infoModel.startDate = dayjs(curDate).format('YYYY-MM-DD')
        infoModel.expireDate = dayjs(curDate).set('year', curDate.year() + 1).format('YYYY-MM-DD')
      }
      const res: MembershipInfoResp = {
        code: 0,
        data: {
          isSubscribed: infoModel.isSubscribed,
          startDate: infoModel.startDate,
          expireDate: infoModel.expireDate,
        },
      }
      return [HttpStatusCode.Ok, res]
    })
  }
}

