import { ObservedInfoItem, FormGroup, FormType } from 'collect_personal_info';
import { iData, UserInfoModel, AuthCache } from 'commonlib';
import { UserApis, UserInfoType } from 'lib_network';
import { ToastDialog } from '@hw-agconnect/ui-toast';

@ObservedV2
export class EditProfileVM {
  @Trace
  userInfo: UserInfoModel = iData.global.userInfo;

  static isGuestMode(): boolean {
    return AuthCache.getUserType() === 'guest';
  }

  @Trace avatarItem: ObservedInfoItem = new ObservedInfoItem({
    type: FormType.CHOOSE_AVATAR,
    label: '头像',
    value: this.userInfo.avatar ? this.userInfo.avatar : $r('app.media.default_avatar'),
    onChange: async (param?: Object) => {
      const res = await UserApis.updateUserInfo({
        type: UserInfoType.AVATAR,
        value: param as string,
      })
      if (res.code === 0) {
        this.avatarItem.value = param as string;
        iData.global.userInfo.avatar = param as string;
      }
    },
  });
  @Trace nickNameItem: ObservedInfoItem = new ObservedInfoItem({
    type: FormType.TEXT_INPUT,
    label: '昵称',
    value: this.userInfo.nickname,
    minLength: 2,
    maxLength: 10,
    placeholderText: '请输入昵称',
    invocation: (_param: Object) => {
      return Promise.resolve();
    },
    validMessageText: '内容为空，请输入后保存',
    onChange: async (param?: Object) => {
      const res = await UserApis.updateUserInfo({
        type: UserInfoType.NICKNAME,
        value: param as string,
      })
      if (res.code === 0) {
        this.nickNameItem.value = param as string;
        iData.global.userInfo.nickname = param as string;
      }
    },
  })
  @Trace genderItem: ObservedInfoItem = new ObservedInfoItem({
    type: FormType.DROP_SELECT,
    label: '性别',
    selectOptions: [
      {
        id: 0,
        value: 0,
        label: '男',
      },
      {
        id: 1,
        value: 1,
        label: '女',
      },
      {
        id: 2,
        value: 2,
        label: '保密',
      },
    ],
    value: this.userInfo.gender,
    invocation: (_param: Object) => {
      return Promise.resolve();
    },
    onChange: async (param?: Object) => {
      const res = await UserApis.updateUserInfo({
        type: UserInfoType.GENDER,
        value: param as number,
      })
      if (res.code === 0) {
        this.genderItem.value = param as number;
        iData.global.userInfo.gender = param as number;
      }
    },
  })
  @Trace birthItem: ObservedInfoItem = new ObservedInfoItem({
    type: FormType.DATE_SELECT,
    label: '出生日期',
    sheetOptions: {
      height: 500,
    },
    value: this.userInfo.birth,
    invocation: (_param: Object) => {
      return Promise.resolve();
    },
    onChange: async (param?: Object) => {
      const res = await UserApis.updateUserInfo({
        type: UserInfoType.BIRTH,
        value: param as Date,
      })
      if (res.code === 0) {
        this.birthItem.value = param as Date;
        iData.global.userInfo.birth = param as Date;
      }
    },
  })
  @Trace nameItem: ObservedInfoItem = new ObservedInfoItem({
    type: FormType.TEXT_INPUT,
    label: '姓名',
    value: this.userInfo.name,
    minLength: 2,
    maxLength: 10,
    placeholderText: '请输入姓名',
    invocation: (_param: Object) => {
      return Promise.resolve();
    },
    validMessageText: '内容为空，请输入后保存',
    onChange: async (param?: Object) => {
      if (EditProfileVM.isGuestMode()) {
        ToastDialog.showToast({ message: '请先升级账号后再设置姓名' });
        return;
      }
      const res = await UserApis.updateUserInfo({
        type: UserInfoType.NAME,
        value: param as string,
      })
      if (res.code === 0) {
        this.nameItem.value = param as string;
        iData.global.userInfo.name = param as string;
      }
    },
  })
  @Trace phoneItem: ObservedInfoItem = new ObservedInfoItem({
    type: FormType.PHONE_INPUT,
    label: '手机号码',
    value: this.userInfo.anonymousPhone,
    phoneInfo: {
      codeLength: 6,
      sendCode: (_phone: string) => {
        return new Promise((resolve) => {
          setTimeout(() => {
            resolve()
          }, 1000)
        })
      },
      verifyCode: (_phone: string, _code: string) => {
        return new Promise((resolve) => {
          setTimeout(() => {
            resolve()
          }, 1000)
        })
      },
    },
    onChange: async (param?: Object) => {
      if (EditProfileVM.isGuestMode()) {
        ToastDialog.showToast({ message: '请先升级账号后再设置手机号' });
        return;
      }
      const res = await UserApis.updateUserInfo({
        type: UserInfoType.PHONE,
        value: param as string,
      })
      if (res.code === 0) {
        this.phoneItem.value = param as string;
        iData.global.userInfo.anonymousPhone = param as string;
      }
    },
  })
  @Trace list: FormGroup[] = [];

  constructor() {
    const baseList: FormGroup[] = [
      { list: [this.avatarItem] },
      {
        list: [
          this.nickNameItem,
          this.genderItem,
          this.birthItem
        ],
      },
    ];
    if (!EditProfileVM.isGuestMode()) {
      baseList.push({ list: [this.nameItem, this.phoneItem] });
    }
    this.list = baseList;
  }
}
