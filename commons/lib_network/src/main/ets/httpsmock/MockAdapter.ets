import AxiosMockAdapter from '@hw-agconnect/axios-mock-adapter';
import { UserMockApis } from './mockapis/UserMock';
import instance from '../https/Request';

// 创建mock拦截器
const mockAdapter = new AxiosMockAdapter(instance, {
  delayResponse: 300,
});

// 全局配置，是否启用mock，已禁用（连接真实服务器）
const enableMock: boolean = false;

if (enableMock) {
  const mockApis = [
    new UserMockApis(),
  ];
  mockApis.forEach((api) => {
    api.start(mockAdapter);
  });
}