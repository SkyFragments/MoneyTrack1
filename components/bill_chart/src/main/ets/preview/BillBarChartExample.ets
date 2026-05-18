import { MOCK_BAR_CHART_LIST } from './Mockdata';
import { BillBarChart } from '../components/BillBarChart';


@Entry
@ComponentV2
struct BillBarChartExample {
  build() {
    Column() {
      BillBarChart({
        chartData: {
          month: '2025-05',
          data: MOCK_BAR_CHART_LIST,
          typeLabel:'支出',
          startDate: '',
          endDate: ''
        },
      });
    };
  }
}