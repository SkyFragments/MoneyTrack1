import {
  BarChart,
  BarChartModel,
  BarData,
  BarDataSet,
  BarEntry,
  ChartColor,
  CustomUiInfo,
  EntryOhos,
  EventType,
  Highlight,
  IAxisValueFormatter,
  IBarDataSet,
  JArrayList,
  OnChartValueSelectedListener,
  XAxisPosition,
} from '@ohos/mpchart';
import dayjs from 'dayjs';
import { BillBarChartData, BillBarItem } from '../commons/Types';

@ComponentV2
export struct BillBarChart {
  @Param
  chartData: BillBarChartData = {
    month: '',
    data: [],
    startDate: '',
    endDate: '',
  };
  @Param
  chartHeight: Length = 200;
  @Param
  initColor: number = 0x8094B982;
  @Param
  highlightColor: number = 0x94B982;
  @Param
  markerColor: ResourceColor = '#e6000000';
  @Param
  markerFontSize: Length = 12;
  @Local
  displayData: BillBarItem[] = [];
  @Local
  model: BarChartModel = new BarChartModel();
  @Local
  customUiInfo: CustomUiInfo = new CustomUiInfo(100, 44);
  @Local
  selectedData: BillBarItem | undefined = undefined;

  @Monitor('chartData')
  refreshChart() {
    this.getChartData();
    this.selectedData = undefined;
  }

  async aboutToAppear() {
    await this.initChartSetting();
  }

  // 构造数据选择监听器
  private _valueSelectedListener: OnChartValueSelectedListener = {
    onValueSelected: (e: EntryOhos, h: Highlight) => {
      const idx = h.getX();
      const value = h.getY();
      const date = this.displayData[(idx - 1)]?.date;
      if (typeof date === 'string' && typeof value === 'number') {
        this.selectedData = {
          date,
          value,
        };
      }
    },
    onNothingSelected: () => {
      this.selectedData = undefined;
    },
  };

  build() {
    Column() {
      if (this.chartData.data.length) {
        Text() {
          if (this.selectedData) {
            Span(dayjs(this.selectedData.date as string).format('M月D日'));
            Span((this.chartData.typeLabel ?? '') + ': ');
            Span('¥' + this.selectedData.value);
          }
          Span(' ');
        }
        .width('100%')
        .fontSize(14)
        .fontColor(this.markerColor);

        BarChart({
          model: this.model,
          // 自定义 ui: 传入 builder
          customUiBuilder: this.markerBuilder,
          // 通过什么事件触发
          customUiTriggerEvent: EventType.SingleTap,
          // 自定义ui的位置信息
          customUiInfo: this.customUiInfo,
        })
          .width('100%');
      } else {
        Image($r('app.media.ic_data_empty')).width(80).height(80);
        Text('暂无内容')
          .fontColor('#99000000')
          .fontSize(14)
          .fontWeight(FontWeight.Regular);
      }
    }
    .width('100%')
    .height(this.chartHeight)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  markerBuilder() {
    // 是否在图表content内&&是否有数据
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
      .alignItems(HorizontalAlign.Start)
      .onAppear(() => {
        const timer = setTimeout(() => {
          this.customUiInfo.showUi = false;
          clearTimeout(timer);
        }, 2000);
      })
      .onClick(() => {
        this.customUiInfo.showUi = false;
      });
    }
  }

  async initChartSetting() {
    // 初始化动画时长
    this.model.animateY(1000);
    // 显示图例
    this.model.getLegend()?.setEnabled(false);
    // 显示描述
    this.model.getDescription()?.setEnabled(false);
    // 设置额外偏移量
    this.model.setExtraOffsets(10, 10, 10, 5);
    // 绘制图表背景色
    this.model.setDrawGridBackground(false);
    // 绘制柱状体阴影背景
    this.model.setDrawBarShadow(false);
    // 柱状体上方显示数值
    this.model.setDrawValueAboveBar(false);
    // 为图表添加数据选择的监听器
    this.model.setOnChartValueSelectedListener(this._valueSelectedListener);
    // 设置左轴
    const leftAxis = this.model.getAxisLeft();
    if (leftAxis) {
      leftAxis.setAxisMinimum(0);
      leftAxis.setAxisLineColor(ChartColor.rgb(255, 255, 255));
      leftAxis.setGridColor(ChartColor.argb(60, 0, 0, 0));
      leftAxis.setTextColor(ChartColor.argb(200, 0, 0, 0));
      leftAxis.setLabelXOffset(-10);
    }
    // 设置右轴不显示
    this.model.getAxisRight()?.setEnabled(false);
    // 设置x轴
    const xAxis = this.model.getXAxis();
    if (xAxis) {
      xAxis.setValueFormatter(new MyAxisValueFormatter(this.chartData.month));
      xAxis.setPosition(XAxisPosition.BOTTOM);
      xAxis.setDrawGridLines(false);
      xAxis.setAxisLineColor(ChartColor.argb(60, 0, 0, 0));
      xAxis.setTextColor(ChartColor.argb(200, 0, 0, 0));
    }
    // 初始化图表数据
    this.getChartData();
  }

  async getChartData() {
    // 使用传入的起止日期
    const start = this.chartData.startDate ? dayjs(this.chartData.startDate) : dayjs().startOf('month');
    const end = this.chartData.endDate ? dayjs(this.chartData.endDate) : dayjs().endOf('month');

    // 计算天数差
    const totalDays = end.diff(start, 'day') + 1;

    this.displayData = [];

    // 循环生成从 startDate 到 endDate 的每一天
    for (let i = 0; i < totalDays; i++) {
      const currentDate = start.add(i, 'day');
      const dateStr = currentDate.format('YYYY-MM-DD');

      // 查找当天是否有数据
      const bill = this.chartData.data.find((item) => {
        return item.date === dateStr;
      });

      if (bill) {
        this.displayData.push({
          date: bill.date,
          value: bill.value,
        });
      } else {
        this.displayData.push({
          date: dateStr,
          value: 0,
        });
      }
    }

    this.model.getXAxis()?.setValueFormatter(
      new MyAxisValueFormatter(this.chartData.startDate || this.chartData.month)
    );
    await this.setData();
  }

  async setData() {
    let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
    for (let i = 0; i < this.displayData.length; i++) {
      values.add(new BarEntry(i + 1, this.displayData[i].value));
    }

    let dataSet: BarDataSet = new BarDataSet(values, 'DataSet');
    dataSet.setHighLightColor(this.highlightColor);
    dataSet.setColorByColor(this.initColor);
    dataSet.setDrawValues(false);
    // 显示数据格式化
    let dataSetList: JArrayList<IBarDataSet> = new JArrayList<IBarDataSet>();
    dataSetList.add(dataSet);

    let barData: BarData = new BarData(dataSetList);
    barData.setBarWidth(0.85);
    if (this.model) {
      this.model.setData(barData);
    }
    return barData;
  }
}

class MyAxisValueFormatter implements IAxisValueFormatter {
  referenceDate: string;

  constructor(referenceDate: string) {
    this.referenceDate = referenceDate;
  }

  public getFormattedValue(value: number): string {
    const date = dayjs(this.referenceDate).add(value - 1, 'day');
    return date.format('M.D');
  }
}