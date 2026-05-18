import { BillConstants } from 'bill_base';
import { CustomKeyboardButtonType, CustomKeyboardDisplayType } from './Enums';
import { CustomKeyboardItem } from './Types';

export const CUSTOM_KEYBOARD_LIST: CustomKeyboardItem[] = [
  {
    display: CustomKeyboardDisplayType.TEXT,
    type: CustomKeyboardButtonType.NUMBER,
    text: '1',
  },
  {
    display: CustomKeyboardDisplayType.TEXT,
    type: CustomKeyboardButtonType.NUMBER,
    text: '2',
  },
  {
    display: CustomKeyboardDisplayType.TEXT,
    type: CustomKeyboardButtonType.NUMBER,
    text: '3',
  },
  {
    display: CustomKeyboardDisplayType.TEXT_WITH_IMAGE,
    type: CustomKeyboardButtonType.CALENDAR,
    icon: $r('app.media.ic_calendar'),
    text: '今天',
  },
  {
    display: CustomKeyboardDisplayType.TEXT,
    type: CustomKeyboardButtonType.NUMBER,
    text: '4',
  },
  {
    display: CustomKeyboardDisplayType.TEXT,
    type: CustomKeyboardButtonType.NUMBER,
    text: '5',
  },
  {
    display: CustomKeyboardDisplayType.TEXT,
    type: CustomKeyboardButtonType.NUMBER,
    text: '6',
  },
  {
    display: CustomKeyboardDisplayType.TEXT,
    type: CustomKeyboardButtonType.SUBTRACTION,
    text: '-',
  },
  {
    display: CustomKeyboardDisplayType.TEXT,
    type: CustomKeyboardButtonType.NUMBER,
    text: '7',
  },
  {
    display: CustomKeyboardDisplayType.TEXT,
    type: CustomKeyboardButtonType.NUMBER,
    text: '8',
  },
  {
    display: CustomKeyboardDisplayType.TEXT,
    type: CustomKeyboardButtonType.NUMBER,
    text: '9',
  },
  {
    display: CustomKeyboardDisplayType.TEXT,
    type: CustomKeyboardButtonType.ADDITION,
    text: '+',
  },
  {
    display: CustomKeyboardDisplayType.TEXT,
    type: CustomKeyboardButtonType.POINT,
    text: '.',
  },
  {
    display: CustomKeyboardDisplayType.TEXT,
    type: CustomKeyboardButtonType.NUMBER,
    text: '0',
  },
  {
    display: CustomKeyboardDisplayType.IMAGE,
    type: CustomKeyboardButtonType.DELETE,
    text: '',
    icon: $r('app.media.ic_keyboard_delete'),
  },
  {
    display: CustomKeyboardDisplayType.TEXT,
    type: CustomKeyboardButtonType.CONFIRM,
    text: '完成',
    bgColor: BillConstants.THEME_COLOR,
    fontColor: BillConstants.FONT_COLOR_1_INVERT,
  },
];
