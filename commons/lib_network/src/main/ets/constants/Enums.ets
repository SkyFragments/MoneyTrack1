export enum RequestUrlMap {
  // Sync
  SYNC_PULL = 'sync/pull',
  SYNC_PUSH = 'sync/push',
  // Categories
  CATEGORIES = 'categories',
  // Auth
  AUTH_ME = 'auth/me',
  AUTH_LOGIN = 'auth/login',
  AUTH_REGISTER = 'auth/register',
  AUTH_REFRESH = 'auth/refresh',
  AUTH_HUAWEI_LOGIN = 'auth/huawei-login',
  AUTH_UPGRADE = 'auth/upgrade',
  AUTH_PHONE_LOGIN = 'auth/phone-login',
  AUTH_PHONE_SEND = 'auth/phone-login/send',
  /**
   * 用户相关
   */
  USER_LOGIN = 'user/login',
  USER_LOGOUT = 'user/logout',
  USER_INFO = 'user/info',
  USER_MEMBERSHIP = 'user/membership',
}

export enum UserInfoType {
  /**
   * 个人信息相关
   */
  AVATAR = 'avatar',
  NICKNAME = 'nickname',
  NAME = 'name',
  GENDER = 'gender',
  BIRTH = 'birth',
  PHONE = 'phone'
}