// 支持的信息类型枚举
export enum DataType {
  AVATAR = 'avatar',
  NICK_NAME = 'nickName',
  FULL_NAME = 'fullName',
  GENDER = 'gender',
  BIRTH_DATE = 'birthDate',
  PHONE_NUMBER = 'phoneNumber',
  INTRO_DESC = 'introDesc',
}

// 支持的表单类型枚举
export enum FormType {
  CHOOSE_AVATAR = 'choose_avatar',
  TEXT_INPUT = 'text_input',
  PHONE_INPUT = 'phone_input',
  TEXTAREA = 'textarea',
  DROP_SELECT = 'drop_select',
  DATE_SELECT = 'date_select',
}

// 性别枚举
export enum GenderType {
  MALE = 0,
  FEMALE = 1,
  CONFIDENTIALITY = 2,
}

// 开关模型
export interface SwitchInfo {
  showAvatar?: boolean;
  showNickName?: boolean;
  showFullName?: boolean;
  showGender?: boolean;
  showBirthDate?: boolean;
  showPhoneNumber?: boolean;
  showIntroDesc?: boolean;
}

// 个人数据模型
export interface PersonalInfo {
  avatar?: ResourceStr;
  nickName?: ResourceStr;
  fullName?: ResourceStr;
  gender?: GenderType;
  birthDate?: Date;
  phoneNumber?: string;
  introDesc?: ResourceStr;
}

// 性别模型
export interface GenderOption extends ISelectOption {
  id: number | string;
  label: ResourceStr;
  value: GenderType;
}

// 云侧接口调用模型
export interface ApiHandler {
  updateAvatar?: (param: Object) => Promise<void>;
  updateNickName?: (param: Object) => Promise<void>;
  updateGender?: (param: Object) => Promise<void>;
  updateBirth?: (param: Object) => Promise<void>;
  updateFullName?: (param: Object) => Promise<void>;
  updateIntro?: (param: Object) => Promise<void>;
  updatePhoneInfo?: PhoneApiInfo;
}

// 手机号码接口调用模型
export interface PhoneApiInfo {
  codeLength?: number;
  sendCode: (phone: string) => Promise<void>;
  verifyCode: (phone: string, code: string) => Promise<void>;
}

export interface ISelectOption {
  id: number | string;
  label: ResourceStr;
  value: Object;
}

// 表单模型
export interface InfoItem {
  type: FormType;
  value?: ResourceStr | Date | number | Object;
  label: ResourceStr;
  subLabel?: ResourceStr;
  placeholderText?: ResourceStr;
  validMessageText?: ResourceStr;
  minLength?: number;
  maxLength?: number;
  showValue?: boolean;
  showRightArrow?: boolean;
  selectOptions?: ISelectOption[];
  sheetTitle?: string;
  sheetOptions?: SheetOptions;
  invocation?: (param: Object) => Promise<void>;
  phoneInfo?: PhoneApiInfo;
  onChange?: (param?: Object) => void;
  onClick?: () => void;
}