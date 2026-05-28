import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from 'commonlib';
import { AuthCache } from 'commonlib';
import { AuthApis } from './apis/Auth';

const LOCAL_IP = '1.12.234.7';
const PORT = 8080;
const baseURL = 'http://' + LOCAL_IP + ':' + PORT;

Logger.info('Request', '=== Request module initialized ===');
Logger.info('Request', 'baseURL=' + baseURL);

function buildFullUrl(url: string, params?: Record<string, string>): string {
  let fullUrl = url.startsWith('http') ? url : baseURL + url;
  if (params) {
    const qs = Object.entries(params)
      .map((e) => encodeURIComponent(e[0]) + '=' + encodeURIComponent(e[1]))
      .join('&');
    fullUrl += (fullUrl.includes('?') ? '&' : '?') + qs;
  }
  return fullUrl;
}

function getHeaders(token?: string): Record<string, string> {
  const accessToken = token ?? AuthCache.getAccessToken();
  const headers: Record<string, string> = {
    'Content-Type': 'application/json'
  };
  if (accessToken) {
    headers['Authorization'] = 'Bearer ' + accessToken;
  }
  return headers;
}

interface DoRequestOptions {
  data?: object | string;
  params?: Record<string, string>;
  timeout?: number;
}

interface ErrorResponse {
  code: number;
  msg: string;
  data: null;
}

const HTTP_TOKEN_REFRESHED_CODE = -401;

async function tryRefreshToken(): Promise<boolean> {
  const refreshToken = AuthCache.getRefreshToken();
  if (!refreshToken) {
    return false;
  }
  try {
    const res = await AuthApis.refresh({ refreshToken });
    if (res.code === 0 && res.data) {
      AuthCache.setTokens(res.data.accessToken, res.data.refreshToken);
      return true;
    }
  } catch (_e) {
    Logger.warn('Request', 'Token refresh failed: ' + _e);
  }
  return false;
}

function doRequest<T>(url: string, method: http.RequestMethod, options: DoRequestOptions): Promise<T> {
  const fullUrl = buildFullUrl(url, options.params ?? undefined);
  const timeout = options.timeout ?? 30000;
  let extraData: string | undefined;
  if (options.data !== undefined) {
    extraData = typeof options.data === 'string' ? options.data : JSON.stringify(options.data);
  }

  const attempt = (retryToken?: string): Promise<T> => {
    return new Promise<T>((resolve, reject) => {
      const httpRequest = http.createHttp();
      const headers = getHeaders(retryToken);
      Logger.info('Request', '[Request] >>> ' + method + ' >>> ' + fullUrl);
      if (retryToken) {
        Logger.info('Request', '[Request] Using refreshed token');
      }

      httpRequest.request(fullUrl, {
        method: method,
        header: headers,
        extraData: extraData,
        connectTimeout: timeout,
        readTimeout: timeout,
        usingProxy: false,
        expectDataType: http.HttpDataType.STRING,
      }).then((resp: http.HttpResponse) => {
        Logger.info('Request', '[Request] <<< ' + method + ' OK <<< responseCode=' + resp.responseCode);
        const resultStr = resp.result as string;

        if (resp.responseCode !== 200) {
          let errResp: ErrorResponse;
          try {
            const parsedObj: Record<string, string | number> = JSON.parse(resultStr) as Record<string, string | number>;
            errResp = {
              code: typeof parsedObj['code'] === 'number' ? parsedObj['code'] as number : resp.responseCode,
              msg: typeof parsedObj['msg'] === 'string' ? parsedObj['msg'] as string : ('HTTP ' + resp.responseCode),
              data: null
            };
          } catch {
            errResp = { code: resp.responseCode, msg: 'HTTP ' + resp.responseCode, data: null };
          }

          // 401 — try token refresh once
          if (resp.responseCode === 401 && !retryToken) {
            Logger.info('Request', '[Request] Got 401, attempting token refresh...');
            tryRefreshToken().then((refreshed) => {
              httpRequest.destroy();
              if (refreshed) {
                resolve(attempt(AuthCache.getAccessToken()) as Promise<T>);
              } else {
                resolve(errResp as T);
              }
            }).catch(() => {
              resolve(errResp as T);
            });
            return;
          }

          resolve(errResp as T);
          httpRequest.destroy();
          return;
        }

        let parsedData: T;
        try {
          parsedData = JSON.parse(resultStr) as T;
        } catch {
          const fallback: ErrorResponse = { code: resp.responseCode, msg: 'Parse error', data: null };
          resolve(fallback as T);
          httpRequest.destroy();
          return;
        }

        resolve(parsedData);
        httpRequest.destroy();
      }).catch((err: BusinessError) => {
        Logger.error('Request', '[Request] !!! ' + method + ' ERROR !!! code=' + err.code + ', message=' + err.message);
        if (err.code === 2300001 || err.code === 2300002 || err.code === 2300003) {
          Logger.error('Request', '[Request] !!! NETWORK CONNECT ERROR !!!');
        }
        httpRequest.destroy();
        reject(err);
      });
    });
  };

  return attempt();
}

class RequestClient {
  get<T>(url: string): Promise<T> {
    return doRequest<T>(url, http.RequestMethod.GET, {});
  }

  getWithParams<T>(url: string, params: Record<string, string>): Promise<T> {
    return doRequest<T>(url, http.RequestMethod.GET, { params: params });
  }

  post<T>(url: string, data?: object): Promise<T> {
    return doRequest<T>(url, http.RequestMethod.POST, { data: data });
  }

  put<T>(url: string, data?: object): Promise<T> {
    return doRequest<T>(url, http.RequestMethod.PUT, { data: data });
  }

  delete<T>(url: string): Promise<T> {
    return doRequest<T>(url, http.RequestMethod.DELETE, {});
  }

  deleteWithParams<T>(url: string, params: Record<string, string>): Promise<T> {
    return doRequest<T>(url, http.RequestMethod.DELETE, { params: params });
  }
}

const request = new RequestClient();

export default request;