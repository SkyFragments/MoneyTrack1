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
    return config;
  },
  (error: AxiosError): Promise<AxiosError> => {
    return Promise.reject(error);
  }
);

export default instance;
