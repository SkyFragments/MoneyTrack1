export interface BillBarItem {
  date: string;
  value: number;
}

export interface BillBarChartData {
  data: BillBarItem[];
  month: string;
  startDate: string;
  endDate: string;
  typeLabel?: string;
}

export interface BillPieChartItem {
  label: string;
  value: number;
  resource: number;
}

export interface BillRankingItem extends BillPieChartItem {
  barLength: Length;
  color: ResourceColor;
}

export interface ReportTableItem {
  date: string;
  totalIncome: number;
  totalExpense: number;
}
