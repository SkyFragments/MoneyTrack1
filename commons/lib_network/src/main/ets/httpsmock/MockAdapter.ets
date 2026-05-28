// Mock 已禁用，不再使用 AxiosMockAdapter
// 如果需要启用 mock，恢复 AxiosMockAdapter 并更新 request 实例类型
const enableMock: boolean = false;

if (enableMock) {
  // TODO: 需要使用新的 http 模块更新 mock 实现
  console.info('[MockAdapter] mock is disabled');
}

export {};