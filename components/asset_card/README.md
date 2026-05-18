# 资产卡片组件快速入门

- [简介](#简介)
- [约束与限制](#约束与限制)
- [使用](#使用)
- [API参考](#API参考)
- [示例代码](#示例代码)



## 简介

本组件提供了以下两种形式的卡片：

- AssetCard提供了根据传入数据，分组展示资产和负债账户卡片的能力，支持侧滑展示删除按钮，支持根据匿名参数判断是否隐匿资产信息，支持传入回调处理资产账户的点击、删除事件。

- AssetSummaryCard提供了根据传入数据，展示总资产和总负债金额的能力，支持自定义卡片高度、金额展示颜色、卡片背景图，支持根据匿名参数判断是否隐匿资产信息，支持传入回调处理小眼睛点击事件。

| AssetCard                                       | AssetSummaryCard                                             |
| ----------------------------------------------- | ------------------------------------------------------------ |
| ![AssetCardIntro](snapshots/AssetCardIntro.PNG) | ![AssetSummaryCardInrto](snapshots/AssetSummaryCardInrto.PNG) |



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
   b. 在项目根目录build-profile.json5添加asset_base和asset_card模块。

   ```typescript
   // 在项目根目录build-profile.json5填写asset_base和asset_card路径。其中XXX为组件存放的目录名
     "modules": [
       {
         "name": "asset_base",
         "srcPath": "./XXX/asset_base",
       },
       {
         "name": "asset_card",
         "srcPath": "./XXX/asset_card",
       }
     ]
   ```

2. 在根目录oh-package.json5中添加依赖。

   ```typescript
   // XXX为组件存放的目录名称
   "dependencies": {
     "asset_card": "file:./XXX/asset_card",
     "asset_base": "file:./XXX/asset_base"
   }
   ```

3. 使用AssetCard组件。

   a. 引入组件句柄。

   ```ts
   import { AssetCard } from 'asset_card';
   ```

   b. 调用组件。

   ```ts
   import { AssetRecordItem, AssetGroupModel, AssetType, AssetCategory } from 'asset_base';
   import { AssetCard } from 'asset_card';
   
   const MOCK_CREDIT_LIST: AssetRecordItem[] = [
     {
       assetId: 0,
       name: '信用卡',
       icon: $r('app.media.ic_liability_1'),
       type: AssetType.CREDIT,
       subType: 1,
       category: AssetCategory.LIABILITY,
       amount: 300,
     },
   ];
   
   @Entry
   @ComponentV2
   struct PreviewPage {
     @Local
     assetData: AssetGroupModel = new AssetGroupModel();
   
     aboutToAppear(): void {
       this.assetData.credit = MOCK_CREDIT_LIST;
     }
   
     build() {
       Column() {
         AssetCard({
           assetData: this.assetData,
         });
       }
     }
   }
   ```

4. 使用AssetSummaryCard组件

   a. 引入组件句柄。

   ```ts
   import { AssetSummaryCard } from 'asset_card';
   ```

   b. 使用组件。

   ```ts
   import { AssetSummaryCard } from 'asset_card';
   
   @Entry
   @ComponentV2
   struct PreviewPage {
     build() {
       Column(){
         AssetSummaryCard({
           assetData: {
             totalAsset: 3000,
             totalLiability: 300,
           },
         });
       }
       .padding(16)
       .backgroundColor('#eee');
     }
   }
   ```



## API参考

### 接口

#### AssetCard(option?:AssetCardOptions)

资产卡片组件。

**参数：**

| 参数名  | 类型                                          | 是否必填 | 说明                     |
| ------- | --------------------------------------------- | -------- | ------------------------ |
| options | [AssetCardOptions](#AssetCardOptions对象说明) | 否       | 配置资产卡片组件的参数。 |

#### AssetSummaryCard(option?:AssetSummaryCardOptions)

资产概况组件。

**参数：**

| 参数名  | 类型                                                        | 是否必填 | 说明                     |
| ------- | ----------------------------------------------------------- | -------- | ------------------------ |
| options | [AssetSummaryCardOptions](#AssetSummaryCardOptions对象说明) | 否       | 配置资产卡片组件的参数。 |



### AssetCardOptions对象说明

| 名称         | 类型                                                        | 是否必填 | 说明                               |
| ------------ | ----------------------------------------------------------- | -------- | ---------------------------------- |
| assetData    | [AssetGroupModel](#AssetGroupModel对象说明)                 | 否       | 资产数据                           |
| anonymous    | boolean                                                     | 否       | 是否为隐匿展示，默认值false        |
| handleDelete | (id: number) => void                                        | 否       | 资产账户点击删除按钮触发的回调事件 |
| handleClick  | (item: [AssetRecordItem](#AssetRecordItem对象说明)) => void | 否       | 点击资产账户触发的回调事件         |



### AssetSummaryCardOptions对象说明

| 名称            | 类型                                                         | 是否必填 | 说明                                                         |
| --------------- | ------------------------------------------------------------ | -------- | ------------------------------------------------------------ |
| cardHeight      | Length                                                       | 否       | 卡片高度，默认值105                                          |
| anonymous       | boolean                                                      | 否       | 是否匿名显示，默认值false                                    |
| amountTextColor | [ResourceColor](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#resourcecolor) | 否       | 金额文字颜色，默认值#e6000000                                |
| bgImage         | [ResourceStr](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#resourcestr) | 否       | 背景图片资源路径，默认图片为$r('app.media.ic_bg_summary_card') |
| assetData       | [AssetSummary](#AssetSummary对象说明)                        | 否       | 资产数据对象，包含总资产和总负债，默认值{ totalAsset: 0, totalLiability: 0 } |
| handleEyeClick  | () => void                                                   | 否       | 点击眼睛图标事件处理函数                                     |



### AssetGroupModel对象说明

用于资产卡片展示的数据类型，当数据数组发生增加、删除、改变时，支持响应式刷新卡片界面，不支持数组内单条数据内部属性变更时刷新。

| 名称   | 类型                                          | 是否必填 | 说明                     |
| ------ | --------------------------------------------- | -------- | ------------------------ |
| fund   | [AssetRecordItem](#AssetRecordItem对象说明)[] | 否       | 正资产数据数组，默认为[] |
| credit | [AssetRecordItem](#AssetRecordItem对象说明)[] | 否       | 负债数据数组，默认为[]   |



### AssetRecordItem对象说明

单条资产账户的数据类型。

| 名称     | 类型                                                         | 是否必填 | 说明             |
| -------- | ------------------------------------------------------------ | -------- | ---------------- |
| assetId  | number                                                       | 是       | 资产唯一标识符   |
| name     | string                                                       | 是       | 资产名称         |
| icon     | [ResourceStr](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#resourcestr) | 是       | 图标资源路径     |
| type     | [AssetType](#AssetType枚举说明)                              | 是       | 资产类型         |
| subType  | number                                                       | 是       | 资产子类型       |
| category | [AssetCategory](#AssetCategory枚举说明)                      | 是       | 资产分类         |
| amount   | number                                                       | 是       | 资产金额         |
| note     | string                                                       | 否       | 备注信息         |
| isCustom | boolean                                                      | 否       | 是否为自定义资产 |



### AssetSummary对象说明

| 名称           | 类型   | 是否必填 | 说明                |
| -------------- | ------ | -------- | ------------------- |
| totalAsset     | number | 否       | 总资产金额，默认为0 |
| totalLiability | number | 否       | 总负债金额，默认为0 |



### AssetType枚举说明

用于表示资产的主类型。

| 名称   | 值   | 说明     |
| ------ | ---- | -------- |
| FUND   | 1    | 资金账户 |
| CREDIT | 2    | 信用账户 |



### AssetCategory枚举说明

表示资产的分类，用于区分资产和负债类别。

| 名称      | 值   | 说明                       |
| --------- | ---- | -------------------------- |
| ASSET     | 1    | 资产，在净资产计算中为正值 |
| LIABILITY | 2    | 负债，在净资产计算中为负值 |



## 示例代码

### 示例1 （不传入资产数据时展示空数据占位图）

```ts
import { AssetCard } from 'asset_card';

@Entry
@ComponentV2
struct Example1 {
  build() {
    Column(){
      AssetCard();
    }
    .padding(16)
    .backgroundColor('#eee');
  }
}
```

![AssetCardExample1](snapshots/AssetCardExample1.PNG)



### 示例2 （资产数据刷新，点击、删除事件的使用）

```ts
import { AssetCategory, AssetGroupModel, AssetRecordItem, AssetType, Logger } from 'asset_base';
import { AssetCard } from 'asset_card';

const TAG = '[AssetCardExample3]'

const MOCK_FUND_LIST: AssetRecordItem[] = [
  {
    assetId: 0,
    name: '支付宝',
    icon: $r('app.media.ic_asset_4'),
    type: AssetType.FUND,
    subType: 1,
    category: AssetCategory.ASSET,
    amount: 1000,
    note: '余额宝',
  },
];

@Entry
@ComponentV2
struct AssetCardExample3 {
  @Local
  anonymous: boolean = false;
  @Local
  assetData: AssetGroupModel = new AssetGroupModel();

  aboutToAppear(): void {
    this.assetData.fund = MOCK_FUND_LIST;
  }

  build() {
    Column({ space: 16 }) {
      Button('添加资产').onClick(() => {
        const assetId = this.assetData.fund.length;
        const newItem: AssetRecordItem = {
          assetId: assetId,
          name: '自定义' + assetId,
          icon: $r('app.media.ic_asset_others'),
          type: AssetType.FUND,
          subType: 1,
          category: AssetCategory.ASSET,
          amount: 1000,
          note: '测试',
        };
        this.assetData.fund.push(newItem);
      });

      AssetCard({
        assetData: this.assetData,
        handleClick: (item) => {
          try {
            this.getUIContext().getPromptAction().showToast({
              message: `点击了资产账户${item.name},余额为${item.amount}元`,
              alignment: Alignment.Center,
            });
          } catch (err) {
            Logger.error(TAG, 'show toast failed. error:' + JSON.stringify(err));
          }
        },
        handleDelete: (id) => {
          const idx = this.assetData.fund.findIndex((item) => item.assetId === id);
          if (idx) {
            this.assetData.fund.splice(idx, 1);
          }
        },
      });
    }
    .padding(16)
    .backgroundColor('#eee');
  }
}
```

![AssetCardExample3](snapshots/AssetCardExample3.gif)

### 示例3（AssetCard和AssetSummaryCard联合使用）

```ts
import { AssetRecordItem, AssetGroupModel, AssetType, AssetCategory } from 'asset_base';
import { AssetCard, AssetSummaryCard } from 'asset_card';

const MOCK_FUND_LIST: AssetRecordItem[] = [
  {
    assetId: 101,
    name: '支付宝',
    icon: $r('app.media.ic_asset_4'),
    type: AssetType.FUND,
    subType: 1,
    category: AssetCategory.ASSET,
    amount: 1000,
    note: '余额宝',
  },
  {
    assetId: 102,
    name: '微信',
    icon: $r('app.media.ic_asset_5'),
    type: AssetType.FUND,
    subType: 2,
    category: AssetCategory.ASSET,
    amount: 2000,
  },
];

const MOCK_CREDIT_LIST: AssetRecordItem[] = [
  {
    assetId: 201,
    name: '信用卡',
    icon: $r('app.media.ic_liability_1'),
    type: AssetType.CREDIT,
    subType: 1,
    category: AssetCategory.LIABILITY,
    amount: 300,
  },
];

@Entry
@ComponentV2
struct Example3 {
  @Local
  anonymous: boolean = false;
  @Local
  assetData: AssetGroupModel = new AssetGroupModel();

  aboutToAppear(): void {
    this.setData();
  }

  setData() {
    this.assetData.fund = JSON.parse(JSON.stringify(MOCK_FUND_LIST));
    this.assetData.credit = JSON.parse(JSON.stringify(MOCK_CREDIT_LIST));
  }

  @Computed
  get totalAsset() {
    return this.assetData.fund.reduce((pre, cur) => pre + cur.amount, 0);
  }

  @Computed
  get totalLiability() {
    return this.assetData.credit.reduce((pre, cur) => pre + cur.amount, 0);
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Button('重置')
          .onClick(() => {
            this.setData();
          });
        // 总资产卡片
        AssetSummaryCard({
          anonymous: this.anonymous,
          handleEyeClick: () => {
            this.anonymous = !this.anonymous;
          },
          assetData: {
            totalAsset: this.totalAsset,
            totalLiability: this.totalLiability,
          },
        });
        // 资产卡片
        AssetCard({
          assetData: this.assetData,
          anonymous: this.anonymous,
          handleClick: (item: AssetRecordItem) => {
            console.log('当前选中的资产账户信息如下：' + JSON.stringify(item));
          },
          handleDelete: (id: number) => {
            if (id < 200) {
              const idx = this.assetData.fund.findIndex((item) => item.assetId === id);
              if (idx >= 0) {
                this.assetData.fund.splice(idx, 1);
              }
            } else {
              const idx = this.assetData.credit.findIndex((item) => item.assetId === id);
              if (idx >= 0) {
                this.assetData.credit.splice(idx, 1);
              }
            }
          },
        });
      }
      .padding(16)
      .backgroundColor('#eee');
    };
  }
}
```

![AssetSummaryCardExample1](snapshots/AssetSummaryCardExample1.gif)

