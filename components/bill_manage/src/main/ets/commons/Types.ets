import { CustomKeyboardButtonType, CustomKeyboardDisplayType } from './Enums';

export interface CustomKeyboardItem {
  display: CustomKeyboardDisplayType;
  type: CustomKeyboardButtonType;
  text: string;
  icon?: ResourceStr;
  bgColor?: ResourceColor;
  fontColor?: ResourceColor;
}
