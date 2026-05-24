import axios, { AxiosResponse, InternalAxiosRequestConfig, AxiosError } from '@ohos/axios';
import { Logger } from 'commonlib';
import { AuthCache } from 'commonlib';

const baseURL = 'http://1.12.234.7:8080';

const instance = axios.create({
  baseURL,
  timeout: 10 * 3000,
  headers: {},
});

instance.interceptors.request.use(
  (config: InternalAxiosRequestConfig): InternalAxiosRequestConfig => {
    const token = AuthCache.getAccessToken();
    if (token && config.headers) {
      config.headers['Authorization'] = 'Bearer ' + token;
    }
    console.info('[Request] URL=' + config.baseURL + config.url, 'method=' + config.method, 'data=' + JSON.stringify(config.data));
    return config;
  },
  (error: AxiosError): Promise<AxiosError> => {
    console.error('[Request] request error:', error.message, 'url=', error.config?.baseURL || '', error.config?.url || '');
    return Promise.reject(error);
  }
);

instance.interceptors.response.use(
  (response: AxiosResponse) => {
    console.info('[Request] response:', response.status, response.config.url, JSON.stringify(response.data));
    return response;
  },
  (error: AxiosError) => {
    console.error('[Request] response error:', error.response?.status, error.message, 'url=', error.config?.baseURL || '', error.config?.url || '');
    return Promise.reject(error);
  }
);

export default instance;
