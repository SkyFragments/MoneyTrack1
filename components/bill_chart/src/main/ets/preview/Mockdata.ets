import {
  BillBarItem,
  BillPieChartItem,
  ReportTableItem,
} from '../commons/Types';

export const MOCK_BAR_CHART_LIST: BillBarItem[] = [
  {
    date: '2025-05-01',
    value: 400.5,
  },
  {
    date: '2025-05-05',
    value: 50.5,
  },
  {
    date: '2025-05-09',
    value: 200,
  },
  {
    date: '2025-05-24',
    value: 120,
  },
];

export const MOCK_BAR_CHART_LIST2: BillBarItem[] = [
  {
    date: '2025-05-06',
    value: 100,
  },
  {
    date: '2025-05-14',
    value: 198.9,
  },
  {
    date: '2025-05-30',
    value: 3000,
  },
];

export const MOCK_COLOR_LIST: number[] = [
  0x638750, 0x7ea568, 0x94b982, 0xabd39c, 0xc6e5b9, 0xdff3d7, 0xf2fdee,
];

export const MOCK_COLOR_LIST2: number[] = [
  0xd77525, 0xf2992c, 0xfbb935, 0xffce52, 0xffe38e, 0xfff1ca, 0xfffbef,
];

export const MOCK_PIE_CHART_LIST: BillPieChartItem[] = [
  {
    label: '购物',
    value: 400000000.5,
    resource: 104,
  },
  {
    label: '交通',
    value: 50000000.5,
    resource: 102,
  },
  {
    label: '生活缴费',
    value: 200,
    resource: 109,
  },
];

export const MOCK_PIE_CHART_LIST2: BillPieChartItem[] = [
  {
    label: '工资',
    value: 3000,
    resource: 201,
  },
  {
    label: '理财',
    value: 200,
    resource: 202,
  },
];

export const MOCK_TABLE_DATA: ReportTableItem[] = [
  {
    date: '2025-05-01',
    totalIncome: 0,
    totalExpense: 524,
  },
  {
    date: '2025-05-04',
    totalIncome: 3000,
    totalExpense: 50.25,
  },
  {
    date: '2025-05-09',
    totalIncome: 200.8,
    totalExpense: 1000,
  },
];
