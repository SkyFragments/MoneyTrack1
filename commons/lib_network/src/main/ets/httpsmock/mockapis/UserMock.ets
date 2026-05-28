// Mock 已禁用，UserMockApis 不再被调用
// 如果需要启用 mock，恢复完整的 mock 实现
export class UserMockApis {
  public start(_adapter: unknown): void {
    // mock disabled
  }
}
