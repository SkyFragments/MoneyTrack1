import { PersistenceV2 } from '@kit.ArkUI';

@ObservedV2
export class AuthCacheModel {
  @Trace
  public accessToken: string = '';
  @Trace
  public refreshToken: string = '';
  @Trace
  public userId: string = '';
  @Trace
  public userType: string = '';
  @Trace
  public phoneNumber: string = '';
  @Trace
  public lastSyncTime: number = 0;

  clear(): void {
    this.accessToken = '';
    this.refreshToken = '';
    this.userId = '';
    this.userType = '';
    this.phoneNumber = '';
    this.lastSyncTime = 0;
  }
}

const AUTH_CACHE_KEY = 'AuthCacheModel';

class AuthCache {
  private static _instance: AuthCacheModel | null = null;
  private static _persisted: boolean = true;

  static getInstance(): AuthCacheModel {
    if (!AuthCache._instance) {
      const connected = PersistenceV2.connect(
        AuthCacheModel,
        AUTH_CACHE_KEY,
        () => new AuthCacheModel(),
      );
      if (!connected) {
        AuthCache._instance = new AuthCacheModel();
        AuthCache._persisted = false;
        console.error('[AuthCache] PersistenceV2.connect failed — using in-memory storage, tokens will be lost on restart');
      } else {
        AuthCache._instance = connected;
        AuthCache._persisted = true;
      }
    }
    return AuthCache._instance!;
  }

  static isPersisted(): boolean {
    return AuthCache._persisted;
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

  static getUserType(): 'full' | 'guest' {
    const type = AuthCache.getInstance().userType;
    if (type === 'full' || type === 'guest') {
      return type;
    }
    // Uninitialized ('') or unknown value → treat as guest
    return 'guest';
  }

  static setUserType(type: 'full' | 'guest'): void {
    const cache = AuthCache.getInstance();
    cache.userType = type;
  }

  static clearUserType(): void {
    const cache = AuthCache.getInstance();
    cache.userType = '';
  }

  static clear(): void {
    AuthCache.getInstance().clear();
  }

  static getLastSyncTime(): number {
    return AuthCache.getInstance().lastSyncTime;
  }

  static setLastSyncTime(serverTime: number): void {
    AuthCache.getInstance().lastSyncTime = serverTime;
  }
}

export { AuthCache };
