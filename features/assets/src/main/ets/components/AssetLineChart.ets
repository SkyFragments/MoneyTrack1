import {
  JArrayList,
  LineChart,
  LineChartModel,
  LineData,
  LineDataSet,
  EntryOhos,
  ILineDataSet,
  XAxisPosition,
  ChartColor,
  Mode,
  CustomUiInfo,
  EventType,
  Highlight,
  IAxisValueFormatter,
  LegendVerticalAlignment
} from '@ohos/mpchart';
import { AssetTrendItem, TimeRangeType } from 'asset_base';
import dayjs from 'dayjs';

@ComponentV2
export struct AssetLineChart {
  @Param trendData: AssetTrendItem[] = [];
  @Param chartHeight: Length = 200;
  @Param timeRangeType: TimeRangeType = TimeRangeType.MONTH;
  @Local model: LineChartModel = new LineChartModel();
  @Local customUiInfo: CustomUiInfo = new CustomUiInfo(100, 44);
  @Local selectedData: AssetTrendItem | undefined = undefined;

  aboutToAppear(): void {
    this.initChartModel();
    if (this.trendData.length > 0) {
      this.updateChartData();
    }
  }

  private initChartModel() {
    this.model.animateX(1000);
    this.model.setDrawGridBackground(false);
    this.model.getDescription()?.setEnabled(false);
    this.model.getLegend()?.setEnabled(false);
    this.model.setExtraOffsets(10, 10, 10, 5);

    const xAxis = this.model.getXAxis();
    if (xAxis) {
      xAxis.setPosition(XAxisPosition.BOTTOM);
      xAxis.setDrawGridLines(false);
      xAxis.setGranularity(1);
      xAxis.setTextColor(ChartColor.argb(150, 0, 0, 0));
      xAxis.setLabelCount(3, true);
      // 设置自定义格式化器
      xAxis.setValueFormatter(new MyAxisValueFormatter(this.trendData, this.timeRangeType));
    }

    const leftAxis = this.model.getAxisLeft();
    if (leftAxis) {
      leftAxis.setAxisLineColor(ChartColor.rgb(255, 255, 255));
      leftAxis.setGridColor(ChartColor.argb(60, 0, 0, 0));
      leftAxis.setTextColor(ChartColor.argb(200, 0, 0, 0));
      leftAxis.setLabelXOffset(-10);
    }
    this.model.getAxisRight()?.setEnabled(false);

    this.model.setOnChartValueSelectedListener({
      onValueSelected: (e: EntryOhos, h: Highlight) => {
        const idx = h.getX();
        if (idx >= 0 && idx < this.trendData.length) {
          this.selectedData = this.trendData[idx - 1];
          this.customUiInfo.data = e;
          this.customUiInfo.showUi = true;
        }
      },
      onNothingSelected: () => {
        this.selectedData = undefined;
        this.customUiInfo.data = null;
        this.customUiInfo.showUi = false;
        this.customUiInfo.isInbounds = false;
      }
    });
  }

  @Monitor('timeRangeType','trendData')
  async updateChartData() {
    if (this.trendData.length === 0) {
      this.model.clear();
      return;
    }

    const xAxis = this.model.getXAxis();
    if (xAxis) {
      xAxis.setLabelCount(3, true);
      xAxis.setValueFormatter(new MyAxisValueFormatter(this.trendData, this.timeRangeType));
    }

    const values: JArrayList<EntryOhos> = new JArrayList<EntryOhos>();
    this.trendData.forEach((item, index) => {
      values.add(new EntryOhos(index + 1, item.value));
    });

    const dataSet = new LineDataSet(values, 'Asset Trend');
    dataSet.setMode(Mode.LINEAR);
    dataSet.setDrawCircles(false);
    dataSet.setColorByColor(ChartColor.rgb(148, 185, 130));
    dataSet.setLineWidth(1);
    dataSet.setDrawFilled(false);
    dataSet.setDrawValues(false);

    const dataSets: JArrayList<ILineDataSet> = new JArrayList<ILineDataSet>();
    dataSets.add(dataSet);

    const lineData = new LineData(dataSets);
    this.model.setData(lineData);
    this.model.notifyDataSetChanged();
    this.model.getLegend()?.setVerticalAlignment(LegendVerticalAlignment.CENTER);
  }

  @Builder
  markerBuilder() {
    if (this.customUiInfo.isInbounds && this.customUiInfo.data && this.customUiInfo.y) {
      Column() {
        Text() {
          Span(`¥${this.customUiInfo.data.getY()}`);
        }
        .fontSize(14);
      }
      .justifyContent(FlexAlign.Center)
      .padding(12)
      .borderRadius(99)
      .backgroundColor(Color.White)
      .shadow({
        radius: 20,
        color: '#33000000',
        offsetX: 0,
        offsetY: 0,
      })
      .width(this.customUiInfo.width)
      .height(this.customUiInfo.height)
      .margin({ left: this.customUiInfo.x, top: this.customUiInfo.y })
      .onClick(() => {
        this.customUiInfo.showUi = false;
      })
      .onAppear(() => {
        const timer = setTimeout(() => {
          this.customUiInfo.showUi = false;
          clearTimeout(timer);
        }, 2000);
      })
    }
  }

  build() {
    Column() {
      if (this.trendData.length > 0) {
        Text() {
          if (this.selectedData) {
            if (this.timeRangeType === TimeRangeType.YEAR) {
              Span(dayjs(this.selectedData.date as string).format('M月'));
            } else {
              Span(dayjs(this.selectedData.date as string).format('M.D'));
            }
            Span(': ¥' + this.selectedData.value);
          }
        }
        .width('100%')
        .fontSize(14)

        LineChart({
          model: this.model,
          customUiBuilder: this.markerBuilder,
          customUiTriggerEvent: EventType.SingleTap,
          customUiInfo: this.customUiInfo
        })
          .width('100%')
          .height(this.chartHeight);
      } else {
        Column() {
          Image($r('app.media.ic_data_empty'))
            .width(60)
            .height(60)
            .opacity(0.5);
          Text('暂无趋势数据')
            .fontSize(14)
            .fontColor($r('app.color.font_color_level3'))
            .margin({ top: 8 });
        }
        .width('100%')
        .height(this.chartHeight)
        .justifyContent(FlexAlign.Center);
      }
    }
    .width('100%');
  }
}

class MyAxisValueFormatter implements IAxisValueFormatter {
  private data: AssetTrendItem[] = [];
  private type: TimeRangeType = TimeRangeType.MONTH;

  constructor(data: AssetTrendItem[], type: TimeRangeType) {
    this.data = data;
    this.type = type;
  }

  public getFormattedValue(value: number): string {
    const index = Math.round(value) - 1;
    if (index >= 0 && index < this.data.length) {
      const dateStr = this.data[index].date;
      if (this.type === TimeRangeType.YEAR) {
        return dayjs(dateStr).format('M月');
      } else {
        return dayjs(dateStr).format('M.D');
      }
    }
    return '';
  }
}