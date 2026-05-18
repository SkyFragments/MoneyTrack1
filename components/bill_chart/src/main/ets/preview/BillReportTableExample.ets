import { BillReportTable } from '../components/BillReportTable';
import { MOCK_TABLE_DATA } from './Mockdata';

@Entry
@ComponentV2
struct BillReportTableExample {
  build() {
    Column({ space: 16 }) {
      BillReportTable({
        tableData: MOCK_TABLE_DATA,
      });
    }
    .padding(16)
    .backgroundColor('#eee');
  }
}