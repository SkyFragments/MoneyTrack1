import { BillPieChart } from '../components/BillPieChart';
import { MOCK_PIE_CHART_LIST, MOCK_COLOR_LIST } from './Mockdata';

@Entry
@ComponentV2
struct BillPieChartExample {
  build() {
    Column({ space: 16 }) {
      BillPieChart({
        chartData: MOCK_PIE_CHART_LIST,
        colorList: MOCK_COLOR_LIST,
      });
    }
    .padding(16)
    .backgroundColor('#eee');
  }
}