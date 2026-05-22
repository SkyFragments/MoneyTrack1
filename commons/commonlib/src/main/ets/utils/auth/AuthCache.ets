import { PersistenceV2 } from '@kit.ArkUI';

@ObservedV2
export class AuthCacheModel {
  @Trace
  public accessToken: string = '';
  @Trace
  public refreshToken: string = '';
  @Trace
  public userId: string = '';
}

const AUTH_CACHE_KEY = 'AuthCacheModel';

class AuthCache {
  private static _instance: AuthCacheModel | null = null;

  static getInstance(): AuthCacheModel {
    if (!AuthCache._instance) {
      AuthCache._instance = PersistenceV2.connect(
        AuthCacheModel,
        AUTH_CACHE_KEY,
        () => new AuthCacheModel(),
      )!;
    }
    return AuthCache._instance!;
  }

  static setTokens(accessToken: string, refreshToken: string): void {
    const cache = AuthCache.getInstance();
    cache.accessToken = accessToken;
    cache.refreshToken = refreshToken;
  }

  static setUserId(userId: string): void {
    const cache = AuthCache.getInstance();
    cache.userId = userId;
  }

  static getAccessToken(): string {
    return AuthCache.getInstance().accessToken;
  }

  static getRefreshToken(): string {
    return AuthCache.getInstance().refreshToken;
  }

  static clear(): void {
    const cache = AuthCache.getInstance();
    cache.accessToken = '';
    cache.refreshToken = '';
    cache.userId = '';
  }
}

export { AuthCache };
