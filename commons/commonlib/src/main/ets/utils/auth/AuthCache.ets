import { hilog } from '@kit.PerformanceAnalysisKit';
import { PersistenceV2 } from '@kit.ArkUI';

const DOMAIN = 0x0000;
const TAG = '[AuthCache]';

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
        if (!AuthCache._instance) {
          AuthCache._instance = new AuthCacheModel();
          AuthCache._persisted = false;
          hilog.error(DOMAIN, TAG, '[AuthCache] PersistenceV2.connect failed - using in-memory storage');
        }
      } else {
        AuthCache._instance = connected;
        // PersistenceV2 returns a fresh empty model on fresh connect after app restart.
        // If the returned instance is blank (no userType/accessToken/userId),
        // it means the persistent store was empty — user is guest.
        // If it has data, the user was previously logged in.
        if (AuthCache._instance.userType === '' && AuthCache._instance.accessToken === '' &&
          AuthCache._instance.userId === '') {
          AuthCache._persisted = false;
          hilog.info(DOMAIN, TAG, '[AuthCache] PersistenceV2 connected but store is empty - guest mode');
        } else {
          AuthCache._persisted = true;
          hilog.info(DOMAIN, TAG, '[AuthCache] PersistenceV2 restored: userType=%{public}s', AuthCache._instance.userType);
        }
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
