import { BusinessError } from '@kit.BasicServicesKit';
import axios, { AxiosResponse } from '@ohos/axios';
import { Logger } from 'commonlib';

/**
 * TODO: Replace with actual server IP when deploying
 * For local development: http://localhost:3000
 * For HarmonyOS emulator: http://10.0.2.2:3000
 * For real device: http://YOUR_PC_IP:3000
 */
const baseURL = 'http://localhost:3000';

const instance = axios.create({
  baseURL,
  timeout: 10 * 3000,
  headers: {},
});

instance.interceptors.response.use(
  (response: AxiosResponse) => {
    if (response.status === 200) {
      return Promise.resolve(response.data);
    } else {
      Logger.error(
        '[Network]',
        `https request failed：${response.config.url}. error:`,
        JSON.stringify(response.status),
      );
      return Promise.reject(response);
    }
  },
  (error: BusinessError) => {
    Logger.error(
      '[Network]',
      `https request failed：. error:`,
      JSON.stringify(error),
    );
    return Promise.reject(error);
  },
);

export default instance;