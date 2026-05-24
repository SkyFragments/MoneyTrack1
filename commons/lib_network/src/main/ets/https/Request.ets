import axios, { AxiosResponse, InternalAxiosRequestConfig, AxiosError } from '@ohos/axios';
import { Logger } from 'commonlib';
import { AuthCache } from 'commonlib';

const baseURL = 'http://1.12.234.7:80/api';

const instance = axios.create({
  baseURL,
  timeout: 10 * 3000,
  headers: {},
});

instance.interceptors.request.use(
  (config: InternalAxiosRequestConfig): InternalAxiosRequestConfig => {
    const token = AuthCache.getAccessToken();
    console.info('[Request] fullUrl=' + (config.baseURL || '') + (config.url || ''));
    console.info('[Request] method=' + config.method + ' timeout=' + config.timeout + ' data=' + JSON.stringify(config.data));
    console.info('[Request] headers=' + JSON.stringify(config.headers));
    if (token && config.headers) {
      config.headers['Authorization'] = 'Bearer ' + token;
      console.info('[Request] token applied, auth header present');
    } else {
      console.info('[Request] no token, skipping auth header');
    }
    return config;
  },
  (error: AxiosError): Promise<AxiosError> => {
    console.error('[Request] request interceptor ERROR:', error.message);
    console.error('[Request] error config:', error.config ? JSON.stringify({url: error.config.url, baseURL: error.config.baseURL, method: error.config.method}) : 'null');
    return Promise.reject(error);
  }
);

instance.interceptors.response.use(
  (response: AxiosResponse) => {
    console.info('[Request] response OK:', response.status, 'url=' + (response.config.baseURL || '') + (response.config.url || ''));
    console.info('[Request] response data:', JSON.stringify(response.data).substring(0, 200));
    return response;
  },
  (error: AxiosError) => {
    console.error('[Request] response ERROR:', error.message);
    console.error('[Request] response status:', error.response?.status);
    console.error('[Request] response data:', JSON.stringify(error.response?.data || 'none').substring(0, 200));
    console.error('[Request] error config:', error.config ? JSON.stringify({url: error.config.url, baseURL: error.config.baseURL, method: error.config.method}) : 'null');
    return Promise.reject(error);
  }
);

export default instance;
