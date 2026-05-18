# 账单卡片组件快速入门

- [简介](#简介)
- [约束与限制](#约束与限制)
- [使用](#使用)
- [API参考](#API参考)
- [示例代码](#示例代码)



## 简介

本组件提供了以下三种形式的卡片：

- BillCard提供了根据传入数据，展示固定日期账单列表的能力，支持配置卡片各项字号字色等属性，支持配置是否展示当日概况、是否展示侧滑按钮，支持传入回调处理账单条目的点击、删除事件。

- BillSummaryCard提供了根据传入数据，展示总支出和总收入的能力，支持自定义标题和内容的字号字色。

- BillDetail提供了根据传入数据，展示账单详情卡片的能力。支持设置金额、内容的字号字色，支持设置卡片的背景颜色，支持传入回调处理账单的编辑、删除事件。

| BillCard                                                     | BillSummaryCard                                             | BillDetail                                                   |
| ------------------------------------------------------------ | ----------------------------------------------------------- | ------------------------------------------------------------ |
| <img src="snapshots/BillCardIntro.PNG" alt="BillCardIntro" width="300"> | <img src="snapshots/BillSummaryCardIntro.PNG"  width="300"> | <img src="snapshots/BillDetailDisplay.PNG" alt="BillDetailDisplay" width="300"> |





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
   b. 在项目根目录build-profile.json5添加bill_base和bill_card模块。

   ```typescript
   // 在项目根目录build-profile.json5填写bill_base和bill_card路径。其中XXX为组件存放的目录名
     "modules": [
       {
         "name": "bill_base",
         "srcPath": "./XXX/bill_base",
       },
       {
         "name": "bill_card",
         "srcPath": "./XXX/bill_card",
       }
     ]
   ```

2. 在根目录oh-package.json5中添加依赖。

   ```typescript
   // XXX为组件存放的目录名称
   "dependencies": {
     "bill_card": "file:./XXX/bill_card",
     "bill_base": "file:./XXX/bill_base"
   }
   ```

3. 使用BillCard组件。

   a. 引入组件句柄。

   ```typescript
   import { BillCard } from 'bill_card';
   ```

   b. 调用组件，详见[示例1](#示例1（账单卡片数据刷新，点击、删除事件的使用）)。

4. 使用BillSummaryCard组件。

   a. 引入组件句柄

   ```typescript
   import { BillSummaryCard } from 'bill_card';
   ```

   b. 调用组件，详见[示例2](#示例2（账单概况与账单卡片联合使用）)。

5. 使用BillDetail组件。

   a. 引入组件句柄。

   ```typescript
   import { BillDetail } from 'bill_card';
   ```

   b. 调用组件，详见[示例3](#示例3（账单详情展示与编辑、删除事件使用）)。



## API参考

### 接口

#### BillCard(BillCardOption?:BillCardOptions)

账单卡片组件。

**参数：**

| 参数名  | 类型                                        | 是否必填 | 说明                     |
| ------- | ------------------------------------------- | -------- | ------------------------ |
| options | [BillCardOptions](#BillCardOptions对象说明) | 否       | 配置资产卡片组件的参数。 |



#### BillSummaryCard(BillSummaryCardOptions?:BillSummaryCardOptions)

账单概况组件。

**参数：**

| 参数名  | 类型                                                      | 是否必填 | 说明                     |
| ------- | --------------------------------------------------------- | -------- | ------------------------ |
| options | [BillSummaryCardOptions](#BillSummaryCardOptions对象说明) | 否       | 配置资产卡片组件的参数。 |



#### BillDetail(BillDetailOption?:BillDetailOptions)

账单概况组件。

**参数：**

| 参数名  | 类型                                            | 是否必填 | 说明                     |
| ------- | ----------------------------------------------- | -------- | ------------------------ |
| options | [BillDetailOptions](#BillDetailOptions对象说明) | 否       | 配置资产卡片组件的参数。 |



### BillCardOptions对象说明

| 名称                  | 类型                                                         | 是否必填 | 说明                                                 |
| --------------------- | ------------------------------------------------------------ | -------- | ---------------------------------------------------- |
| card                  | [DailyBillGroupModel](#DailyBillGroupModel对象说明)          | 否       | 每日账单分组模型，默认为 `new DailyBillGroupModel()` |
| cardBgColor           | [ResourceColor](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#resourcecolor) | 否       | 卡片背景颜色，默认值为 `#ffffff`                     |
| showSummary           | boolean                                                      | 否       | 是否显示总计，默认值为 `true`                        |
| headerFontSize        | [Length](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#length) | 否       | 标题字体大小，默认值为`12`                           |
| headerFontColor       | [ResourceColor](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#resourcecolor) | 否       | 标题字体颜色，默认值为 `#E6000000`                   |
| deleteButtonFontSize  | [Length](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#length) | 否       | 删除按钮字体大小，默认值为 `14`                      |
| deleteButtonFontColor | [ResourceColor](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#resourcecolor) | 否       | 删除按钮字体颜色，默认值为 `#ffffff`                 |
| deleteButtonBgColor   | [ResourceColor](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#resourcecolor) | 否       | 删除按钮背景颜色，默认值为 `#E84026`                 |
| emptyNoteSize         | [Length](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#length) | 否       | 空提示字体大小，默认值为 `14`                        |
| emptyNoteColor        | [ResourceColor](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#resourcecolor) | 否       | 空提示字体颜色，默认值为 `#99000000`                 |
| dividerColor          | [ResourceColor](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#resourcecolor) | 否       | 分割线颜色，默认值为 `##C4C4C4`                      |
| showOperation         | boolean                                                      | 否       | 是否显示操作按钮，默认值为 `true`                    |
| handleDelete          | (id: number) => void                                         | 否       | 删除按钮点击事件，触发时会传入资产 ID                |
| handleClickItem       | (id: BillCardItem) => void                                   | 否       | 点击卡片项事件，触发时会传入卡片项数                 |



### BillSummaryCardOptions对象说明

| 名称             | 类型                                                         | 是否必填 | 说明                               |
| ---------------- | ------------------------------------------------------------ | -------- | ---------------------------------- |
| totalExpense     | string                                                       | 否       | 总支出，默认值为 `'0.00'`          |
| totalIncome      | string                                                       | 否       | 总收入，默认值为 `'0.00'`          |
| titleFontSize    | [Length](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#length) | 否       | 标题字体大小，默认值为 `12`        |
| titleFontColor   | [ResourceColor](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#resourcecolor) | 否       | 标题字体颜色，默认值为 `#99000000` |
| contentFontSize  | [Length](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#length) | 否       | 内容字体大小，默认值为 `18`        |
| contentFontColor | [ResourceColor](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#resourcecolor) | 否       | 内容字体颜色，默认值为 `#E6000000` |



### BillDetailOptions对象说明

| 名称             | 类型                                                         | 是否必填 | 说明                               |
| ---------------- | ------------------------------------------------------------ | -------- | ---------------------------------- |
| bill             | [BillCardItem](#BillCardItem对象说明)                        | 是       | 账单详情数据，必填字段             |
| amountFontColor  | [ResourceColor](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#resourcecolor) | 否       | 标题字体颜色，默认值为 `#E6000000` |
| amountFontSize   | [Length](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#length) | 否       | 金额字体大小，默认值为 `24`        |
| contentFontSize  | [Length](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#length) | 否       | 内容字体大小，默认值为 `14`        |
| contentFontColor | [ResourceColor](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#resourcecolor) | 否       | 内容字体颜色，默认值为 `#E6000000` |
| bgColor          | [ResourceColor](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#resourcecolor) | 否       | 背景颜色，默认值为 `#ffffff`       |
| handleDelete     | () => void                                                   | 否       | 删除按钮点击事件处理函数           |
| handleEdit       | () => void                                                   | 否       | 编辑按钮点击事件处理函数           |



### DailyBillGroupModel对象说明

| 名称    | 类型                                    | 是否必填 | 说明                              |
| ------- | --------------------------------------- | -------- | --------------------------------- |
| dateStr | string                                  | 否       | 日期字符串，默认值为空字符串 `""` |
| list    | [BillCardItem](#BillCardItem对象说明)[] | 否       | 账单项列表，默认值为空数组 `[]`   |



### BillCardItem对象说明

| 名称          | 类型                                                         | 是否必填 | 说明                      |
| ------------- | ------------------------------------------------------------ | -------- | ------------------------- |
| accountId     | number                                                       | 是       | 账户 ID                   |
| date          | string                                                       | 是       | 交易日期                  |
| transactionId | number                                                       | 是       | 交易 ID                   |
| resource      | number                                                       | 是       | 资源 ID                   |
| icon          | [ResourceStr](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#resourcestr) | 是       | 图标资源字符串            |
| title         | string                                                       | 是       | 交易标题                  |
| note          | string                                                       | 否       | 交易备注（可选）          |
| amount        | number                                                       | 是       | 交易金额                  |
| type          | [BalanceChangeType](#BalanceChangeType枚举说明)              | 是       | 余额变化类型（收入/支出） |
| assetId       | number                                                       | 否       | 资产 ID（可选）           |
| assetName     | string                                                       | 否       | 资产名称（可选）          |



### BalanceChangeType枚举说明

| 名称    | 值        | 说明 |
| ------- | --------- | ---- |
| EXPENSE | 'expense' | 支出 |
| INCOME  | 'income'  | 收入 |



## 示例代码

### 示例1（账单卡片数据刷新，点击、删除事件的使用）

```ts
import { BalanceChangeType, BillCardItem, DailyBillGroupModel } from 'bill_base';
import { BillCard } from 'bill_card';

@Entry
@ComponentV2
struct BillCardExample2 {
  @Local model: DailyBillGroupModel = new DailyBillGroupModel();

  aboutToAppear(): void {
    this.model.dateStr = '2025-05-30';
  }

  build() {
    Column({ space: 16 }) {
      Button('添加账单')
        .onClick(() => {
          const newItem: BillCardItem = {
            accountId: 1,
            date: '2025-05-30',
            transactionId: new Date().getTime(),
            resource: 100,
            icon: $r('app.media.ic_expense_0'),
            title: '餐饮',
            note: '黄焖鸡',
            amount: 30,
            type: BalanceChangeType.EXPENSE,
          };
          this.model.list.push(newItem);
        });

      BillCard({
        card: this.model,
        handleDelete: (id) => {
          const idx = this.model.list.findIndex((item) => item.transactionId === id);
          if (idx) {
            this.model.list.splice(idx, 1);
          }
        },
      });
    }
    .padding(16)
    .backgroundColor('#eee');
  }
}
```

<img src="snapshots/BillCardExample2.gif" alt="BillCardExample2" width="300">

### 示例2（账单概况与账单卡片联合使用）

```ts
import { BalanceChangeType, BillCardItem, DailyBillGroupModel } from 'bill_base';
import { BillCard, BillSummaryCard } from 'bill_card';

@Entry
@ComponentV2
struct BillSummaryCardExample1 {
  @Local model: DailyBillGroupModel = new DailyBillGroupModel();

  @Computed
  get totalExpense() {
    return this.model.list.reduce((pre, cur) => pre + cur.amount, 0).toFixed(2);
  }

  aboutToAppear(): void {
    this.model.dateStr = '2025-05-30';
  }

  build() {
    Column({ space: 16 }) {
      Button('添加账单')
        .onClick(() => {
          const newItem: BillCardItem = {
            accountId: 1,
            date: '2025-05-30',
            transactionId: new Date().getTime(),
            resource: 100,
            icon: $r('app.media.ic_expense_0'),
            title: '餐饮',
            note: '黄焖鸡',
            amount: 30,
            type: BalanceChangeType.EXPENSE,
          };
          this.model.list.push(newItem);
        });

      BillSummaryCard({
        totalExpense: this.totalExpense,
      });

      BillCard({
        card: this.model,
        handleDelete: (id) => {
          const idx = this.model.list.findIndex((item) => item.transactionId === id);
          if (idx) {
            this.model.list.splice(idx, 1);
          }
        },
      });
    }
    .padding(16)
    .backgroundColor('#eee');
  }
}
```

<img src="snapshots/BillSummaryCardExample1.gif" alt="BillSummaryCardExample1" width="300">



### 示例3（账单详情展示与编辑、删除事件使用）

```ts
import { BalanceChangeType, BillCardItem, Logger } from 'bill_base';
import { BillDetail } from 'bill_card';

const TAG = '[BillDetailExample1]'

const MOCK_BILL_ITEM: BillCardItem =
  {
    accountId: 1,
    date: '2025-05-15',
    transactionId: 1,
    resource: 100,
    icon: $r('app.media.ic_expense_0'),
    title: '餐饮',
    note: '黄焖鸡',
    amount: 30,
    type: BalanceChangeType.EXPENSE,
    assetName: '支付宝',
  };

@Entry
@ComponentV2
struct BillDetailExample1 {
  @Local bill: BillCardItem = MOCK_BILL_ITEM;

  build() {
    Column() {
      // 账单卡片
      BillDetail({
        bill: this.bill,
        amountFontColor: Color.Pink,
        handleEdit: () => {
          try {
            this.getUIContext().getPromptAction().showToast({
              message: '触发了账单的编辑事件，随机生成一个金额',
              alignment: Alignment.Top
            });
          } catch (err) {
            Logger.error(TAG, 'show toast failed. error:' + JSON.stringify(err));
          }
          const newBill = JSON.parse(JSON.stringify(MOCK_BILL_ITEM)) as BillCardItem;
          newBill.amount = new Date().getSeconds();
          this.bill = newBill;
        },
        handleDelete: () => {
          try {
            this.getUIContext().getPromptAction().showToast({
              message: '触发了账单的删除事件',
              alignment: Alignment.Top
            });
          } catch (err) {
            Logger.error(TAG, 'show toast failed. error:' + JSON.stringify(err));
          }
        },
      });
    }
    .padding(16)
    .backgroundColor('#eee');
  }
}
```

<img src="snapshots/BillDetailExample1.gif" alt="BillDetailExample1" width="300">

