export interface BaseResponse<T = void> {
  code: number;
  msg?: string;
  data?: T;
}
