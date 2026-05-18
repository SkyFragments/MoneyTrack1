# 账单图表组件快速入门

- [简介](#简介)
- [约束与限制](#约束与限制)
- [使用](#使用)
- [API参考](#API参考)
- [示例代码](#示例代码)



## 简介

本组件提供以下几种形式的账单图表：

- BillBarChart 提供了根据传入数据，展示账单柱状图的能力。支持设置图表高度、颜色、标记样式等参数，支持自定义 UI 信息和交互逻辑。

- BillPieChart 提供了根据传入数据，展示饼图的能力。支持设置图表数据、颜色、字体样式、高度等参数，便于展示分类数据的占比关系。

- BillRanking 提供了根据传入数据，展示账单项金额排行榜的能力。支持设置颜色、数据、最大条目长度、标签样式等参数，支持处理条目点击事件。

- BillReportTable 提供了根据传入数据，展示报表表格的能力。支持设置表格数据、字体大小、颜色、排序方向等参数，便于展示账单的详细信息。

- BillCalendar 提供了根据传入数据，展示日历视图的能力。支持设置月份、卡片高度、背景颜色等参数，支持处理日期点击事件。

| BillBarChart                                                 | BillPieChart                                                 | BillRanking                                                  | BillReportTable                                              | BillCalendar                                                 |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| <img src="snapshots/BillBarChartExample.PNG" alt="BillBarChartExample" width="300"> | <img src="snapshots/BillPieChartExample.PNG" alt="BillPieChart" width="300"> | <img src="snapshots/BillRankingExample.PNG" alt="BillRanking" width="300"> | <img src="snapshots/BillReportTable.PNG" alt="BillReportTable" width="300"> | <img src="snapshots/BillCalendarExample.PNG" alt="BillCalendarExample" width="300"> |



## 约束与限制

### 环境

* DevEco Studio版本：DevEco Studio 5.0.2 Release及以上
* HarmonyOS SDK版本：HarmonyOS 5.0.2 Release SDK及以上
* 设备类型：华为手机（包括双折叠和阔折叠）
* 系统版本：HarmonyOS 5.0.2(14)及以上

### 权限

无


## 使用

1. 安装组件。

   如果是在DevEco Studio使用插件集成组件，则无需安装组件，请忽略此步骤。

   如果是从生态市场下载组件，请参考以下步骤安装组件。

   a. 解压下载的组件包，将包中所有文件夹拷贝至您工程根目录的XXX目录下。
   b. 在项目根目录build-profile.json5添加bill_chart模块。

   ```typescript
   // 在项目根目录build-profile.json5填写bill_chart路径。其中XXX为组件存放的目录名
     "modules": [
       {
         "name": "bill_chart",
         "srcPath": "./XXX/bill_chart",
       }
     ]
   ```

2. 在根目录oh-package.json5中添加依赖。

   ```typescript
   // XXX为组件存放的目录名称
   "dependencies": {
     "bill_chart": "file:./XXX/bill_chart",
   }
   ```

3. 引入组件句柄

   ```ts
   import { 
       BillBarChart,
       BillPieChart,
       BillRanking,
       BillReportTable,
       BillCalendar,
   } from 'bill_chart';
   ```

4. 调用组件，详见[示例1](#示例1（账单图表的显示与切换）)。详细参数配置说明参见[API参考](#API参考)。



## API参考

### 接口

#### BillBarChart(options?:BillBarChartOptions)

柱状图组件。

**参数：**

| 参数名  | 类型                                                | 是否必填 | 说明                   |
| ------- | --------------------------------------------------- | -------- | ---------------------- |
| options | [BillBarChartOptions](#BillBarChartOptions对象说明) | 否       | 配置柱状图组件的参数。 |



#### BillPieChart(options?:BillPieChartOptions)

饼图组件。

**参数：**

| 参数名  | 类型                                                | 是否必填 | 说明                 |
| ------- | --------------------------------------------------- | -------- | -------------------- |
| options | [BillPieChartOptions](#BillPieChartOptions对象说明) | 否       | 配置饼图组件的参数。 |



#### BillRanking(options?:BillRankingOptions)

排行榜组件。

**参数：**

| 参数名  | 类型                                              | 是否必填 | 说明                   |
| ------- | ------------------------------------------------- | -------- | ---------------------- |
| options | [BillRankingOptions](#BillRankingOptions对象说明) | 否       | 配置排行榜组件的参数。 |



#### BillReportTable(options?:BillReportTableOptions)

报表表格组件。

**参数：**

| 参数名  | 类型                                                      | 是否必填 | 说明                     |
| ------- | --------------------------------------------------------- | -------- | ------------------------ |
| options | [BillReportTableOptions](#BillReportTableOptions对象说明) | 否       | 配置报表表格组件的参数。 |



#### BillCalendar(options?:BillCalendarOptions)

日历组件。

**参数：**

| 参数名  | 类型                                                | 是否必填 | 说明                 |
| ------- | --------------------------------------------------- | -------- | -------------------- |
| options | [BillCalendarOptions](#BillCalendarOptions对象说明) | 否       | 配置日历组件的参数。 |



### BillBarChartOptions对象说明

| 名称           | 类型                                                         | 是否必填 | 说明                                  |
| -------------- | ------------------------------------------------------------ | -------- | ------------------------------------- |
| chartData      | [BillBarChartData](#BillBarChartData接口说明)                | 是       | 柱状图数据，必填字段                  |
| chartHeight    | [Length](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#length) | 否       | 柱状图高度，默认值为 `200`            |
| initColor      | number                                                       | 否       | 柱状图初始颜色，默认值为 `0x8094B982` |
| highlightColor | number                                                       | 否       | 柱状图高亮颜色，默认值为 `0x94B982`   |
| markerColor    | [ResourceColor](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#resourcecolor) | 否       | 标记颜色，默认值为 `#e6000000`        |
| markerFontSize | [Length](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#length) | 否       | 标记字体大小，默认值为 `12`           |



### BillPieChartOptions对象说明

| 名称           | 类型                                                         | 是否必填 | 说明                                    |
| -------------- | ------------------------------------------------------------ | -------- | --------------------------------------- |
| chartData      | [BillPieChartItem](#BillPieChartItem接口说明)[]              | 否       | 饼图数据数组，默认值为空数组 `[]`       |
| colorList      | number[]                                                     | 否       | 饼图颜色列表，默认值为空数组 `[]`       |
| valueColor     | number                                                       | 否       | 数据值的颜色，默认值为 `0x000000`       |
| valueSize      | number                                                       | 否       | 数据值的字体大小，默认值为 `10`         |
| labelColor     | number                                                       | 否       | 数据标签的颜色，默认值为`0x000000`      |
| labelSize      | number                                                       | 否       | 数据标签的字体大小，默认值为 `10`       |
| valueLineColor | number                                                       | 否       | 数据值的连接线颜色，默认值为 `0xd0d0d0` |
| chartHeight    | [Length](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#length) | 否       | 饼图的高度，默认值为 `200`              |



### BillRankingOptions对象说明

| 名称           | 类型                                                         | 是否必填 | 说明                                             |
| -------------- | ------------------------------------------------------------ | -------- | ------------------------------------------------ |
| colorList      | number[]                                                     | 否       | 排行榜条目颜色列表，用于设置每个条目的颜色       |
| chartData      | [BillPieChartItem](#BillPieChartItem接口说明)[]              | 否       | 排行榜数据数组，用于展示排行榜的内容             |
| maxBarLength   | number                                                       | 否       | 排行榜条目的最大长度，默认值为 `180`             |
| labelColor     | [ResourceColor](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#resourcecolor) | 否       | 排行榜标签的颜色，默认值为 `#e6000000`           |
| labelSize      | [Length](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#length) | 否       | 排行榜标签的字体大小，默认值为 `12`              |
| handleClickBar | (resource: number) => void                                   | 否       | 条目点击事件回调函数，接收点击的条目资源标识参数 |



### BillReportTableOptions对象说明

| 名称             | 类型                                                         | 是否必填 | 说明                                   |
| ---------------- | ------------------------------------------------------------ | -------- | -------------------------------------- |
| tableData        | [ReportTableItem](#ReportTableItem接口说明)[]                | 否       | 表格数据数组，默认值为空数组 `[]`      |
| headerFontSize   | [Length](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#length) | 否       | 表头字体大小，默认值为 `16`            |
| headerFontColor  | [ResourceColor](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#resourcecolor) | 否       | 表头字体颜色，默认值为 `#e6000000`     |
| contentFontSize  | [Length](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#length) | 否       | 表格内容字体大小，默认值为 `14`        |
| contentFontColor | [ResourceColor](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#resourcecolor) | 否       | 表格内容字体颜色，默认值为 `#e6000000` |
| ascend           | boolean                                                      | 否       | 是否按升序排序，默认值为 `true`        |



### BillCalendarOptions对象说明

| 名称                | 类型                                                         | 是否必填 | 说明                                                         |
| ------------------- | ------------------------------------------------------------ | -------- | ------------------------------------------------------------ |
| month               | string                                                       | 否       | 月份字符串，格式YYYY-MM，默认值为 当前月份                   |
| selectedDateSummary | [CalendarBillSummaryModel](#CalendarBillSummaryModel对象说明) | 否       | 选中日期的账单摘要，默认值为 `new CalendarBillSummaryModel()` |
| calendarHeight      | [Length](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#length) | 否       | 日历视图的高度，默认值为 `360`                               |
| bgColor             | [ResourceColor](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#resourcecolor) | 否       | 日历视图的背景颜色，默认值为 `#ffffff`                       |
| handleDateClick     | (dateStr: string) => void                                    | 否       | 日期点击事件回调函数，接收点击的日期字符串参数，格式为YYYY-MM-DD |



### BillBarChartData接口说明

| 名称  | 类型                                  | 是否必填 | 说明           |
| ----- | ------------------------------------- | -------- | -------------- |
| data  | [BillBarItem](#BillBarItem接口说明)[] | 是       | 账单数据数组   |
| month | string                                | 是       | 当前月份字符串 |



### BillBarItem接口说明

| 名称  | 类型   | 是否必填 | 说明                       |
| ----- | ------ | -------- | -------------------------- |
| date  | string | 是       | 日期字符串，格式YYYY-MM-DD |
| value | number | 是       | 对应的金额                 |



### BillPieChartItem接口说明

| 名称     | 类型   | 是否必填 | 说明             |
| -------- | ------ | -------- | ---------------- |
| label    | string | 是       | 数据项的标签     |
| value    | number | 是       | 数据项的值       |
| resource | number | 是       | 数据项的资源标识 |



### ReportTableItem接口说明

**字段说明**

| 名称         | 类型   | 是否必填 | 说明           |
| ------------ | ------ | -------- | -------------- |
| date         | string | 是       | 日期字符串     |
| totalIncome  | number | 是       | 当日总收入金额 |
| totalExpense | number | 是       | 当日总支出金额 |



### CalendarBillSummaryModel对象说明

| 名称         | 类型   | 是否必填 | 说明                      |
| ------------ | ------ | -------- | ------------------------- |
| date         | string | 否       | 日期字符串，默认值为''    |
| totalExpense | number | 否       | 当日总支出金额, 默认值为0 |
| totalIncome  | number | 否       | 当日总收入金额, 默认值为0 |



## 示例代码

### 示例1（账单图表的显示与切换）

```ts
import {
  BillBarItem,
  BillPieChart,
  BillPieChartItem,
  BillRanking,
  BillBarChart,
  BillReportTable,
  BillCalendar,
  BillBarChartData,
  CalendarBillSummaryModel,
  ReportTableItem,
} from 'bill_chart';

const MOCK_BAR_CHART_LIST: BillBarItem[] = [
  {
    date: '05-01',
    value: 400.5,
  },
  {
    date: '05-05',
    value: 50.5,
  },
  {
    date: '05-09',
    value: 200,
  },
  {
    date: '05-24',
    value: 120,
  },
];

const MOCK_BAR_CHART_LIST2: BillBarItem[] = [
  {
    date: '05-06',
    value: 100,
  },
  {
    date: '05-14',
    value: 198.9,
  },
  {
    date: '05-30',
    value: 3000,
  },
];

const MOCK_COLOR_LIST: number[] = [
  0x638750, 0x7ea568, 0x94b982, 0xabd39c, 0xc6e5b9, 0xdff3d7, 0xf2fdee,
];

const MOCK_COLOR_LIST2: number[] = [
  0xd77525, 0xf2992c, 0xfbb935, 0xffce52, 0xffe38e, 0xfff1ca, 0xfffbef,
];

const MOCK_PIE_CHART_LIST: BillPieChartItem[] = [
  {
    label: '购物',
    value: 400.5,
    resource: 104,
  },
  {
    label: '交通',
    value: 50.5,
    resource: 102,
  },
  {
    label: '生活缴费',
    value: 200,
    resource: 109,
  },
];

const MOCK_PIE_CHART_LIST2: BillPieChartItem[] = [
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

const MOCK_TABLE_DATA: ReportTableItem[] = [
  {
    date: '05-01',
    totalIncome: 0,
    totalExpense: 524,
  },
  {
    date: '05-04',
    totalIncome: 3000,
    totalExpense: 50.25,
  },
  {
    date: '05-09',
    totalIncome: 200.8,
    totalExpense: 1000,
  },
];


@Entry
@ComponentV2
struct PreviewPage {
  @Local showChart: boolean = true;
  @Local isExpense: boolean = true;
  @Local summary: CalendarBillSummaryModel = new CalendarBillSummaryModel();

  @Computed
  get barData(): BillBarChartData {
    const list = this.isExpense ? MOCK_BAR_CHART_LIST : MOCK_BAR_CHART_LIST2;
    return {
      month: '2025-05',
      data: list,
      startDate: '',
      endDate: ''
    };
  }

  @Computed
  get barColor() {
    return this.isExpense ? 0x8094b982 : 0x80f2992c;
  }

  @Computed
  get colorList() {
    return this.isExpense ? MOCK_COLOR_LIST : MOCK_COLOR_LIST2;
  }

  @Computed
  get pieData() {
    return this.isExpense ? MOCK_PIE_CHART_LIST : MOCK_PIE_CHART_LIST2;
  }

  build() {
    Column({ space: 16 }) {
      Row() {
        Text(this.showChart ? '图表' : '日历').fontSize(18).fontWeight(FontWeight.Medium);
        Button('切换展示')
          .onClick(() => {
            this.showChart = !this.showChart;
          });
      }.width('100%').justifyContent(FlexAlign.SpaceBetween);

      if (this.showChart) {
        Row() {
          Radio({ value: 'Radio1', group: 'radioGroup' }).checked(true)
            .onChange((isChecked: boolean) => {
              this.isExpense = isChecked;
            });
          Text('支出');
          Blank().width(30);
          Radio({ value: 'Radio2', group: 'radioGroup' }).checked(false)
            .onChange((isChecked: boolean) => {
              this.isExpense = !isChecked;
            });
          Text('收入');
        };

        Scroll() {
          Column({ space: 16 }) {
            // 饼图
            BillPieChart({
              chartData: this.pieData,
              colorList: this.colorList,
            });
            // 账单列表图
            BillRanking({
              chartData: this.pieData,
              colorList: this.colorList,
            });
            //柱状图
            BillBarChart({
              chartData: this.barData,
              initColor: this.barColor,
            });
            // 报表
            BillReportTable({
              tableData: MOCK_TABLE_DATA,
            });
          };
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      } else {
        // 日历视图
        BillCalendar({
          selectedDateSummary: this.summary,
          handleDateClick: (date) => {
            this.summary.date = date;
          },
        });
      }
    }
    .padding(16);
  }
}
```

<img src="snapshots/chartSummaryExample.gif" alt="chartSummaryExample" width="300">