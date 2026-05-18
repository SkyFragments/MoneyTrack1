import { BillRanking } from '../components/BillRanking';
import { MOCK_PIE_CHART_LIST, MOCK_COLOR_LIST } from './Mockdata';

@Entry
@ComponentV2
struct BillRankingExample {
  build() {
    Column({ space: 16 }) {
      BillRanking({
        chartData: MOCK_PIE_CHART_LIST,
        colorList: MOCK_COLOR_LIST,
      });
    }
    .padding(16)
    .backgroundColor('#eee');
  }
}