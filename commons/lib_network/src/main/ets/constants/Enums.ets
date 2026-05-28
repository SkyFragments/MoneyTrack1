export enum RequestUrlMap {
  // Sync
  SYNC_PULL = '/api/sync/pull',
  SYNC_PUSH = '/api/sync/push',
  // Categories
  CATEGORIES = '/api/categories',
  // Auth
  AUTH_ME = '/api/auth/me',
  AUTH_LOGIN = '/api/auth/login',
  AUTH_REGISTER = '/api/auth/register',
  AUTH_REFRESH = '/api/auth/refresh',
  AUTH_HUAWEI_LOGIN = '/api/auth/huawei-login',
  AUTH_UPGRADE = '/api/auth/upgrade',
  AUTH_PHONE_LOGIN = '/api/auth/phone-login',
  AUTH_PHONE_SEND = '/api/auth/phone-login/send',
  /**
   * 用户相关
   */
  USER_LOGIN = '/api/user/login',
  USER_LOGOUT = '/api/user/logout',
  USER_INFO = '/api/user/info',
  USER_MEMBERSHIP = '/api/user/membership',
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