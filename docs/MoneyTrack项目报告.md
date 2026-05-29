![学校标识](media/image1.jpeg){width="5.614583333333333in" height="0.90625in"}

**移动开发综合实训**

**项目报告**

| 项目信息 | 内容 |
|----------|------|
| **项目题目** | 基于HarmonyOS的MoneyTrack记账APP设计与实现 |
| **学号** | （请填写） |
| **姓名** | （请填写） |
| **学院** | 计算机工程学院 |
| **专业** | 网络工程 |
| **指导教师** | （请填写） |

2026年5月25日

---

# MoneyTrack记账APP项目报告

## 报告摘要

本文详细介绍了在鸿蒙操作系统上开发的"MoneyTrack"记账应用，旨在为用户提供便捷的个人收支管理工具。报告涵盖了项目背景、开发环境、功能设计、技术实现、挑战与解决方案等内容，展示了如何基于鸿蒙平台进行记账类应用开发。

项目采用4层模块化架构，前端使用ArkTS开发，后端采用Node.js/Express构建RESTful API。应用实现了账单记录、资产管理、统计图表、用户认证等核心功能，支持本地存储与云端同步，为用户提供完整的个人财务管理解决方案。

---

## 1. 项目背景

随着智能手机的普及，个人财务管理成为日常生活中的重要需求。传统的纸质记账方式已经无法满足用户随时随地记录消费的需求。本项目旨在实现一个功能完善的"记账APP"，帮助用户管理日常收支、统计消费结构、合理规划资产。

### 1.1 项目目标

- 提供便捷的账单记录与管理功能
- 支持多账户资产管理
- 通过图表展示消费统计信息
- 实现用户认证与数据云端同步
- 提供良好的用户体验和界面设计

### 1.2 项目意义

通过本项目的开发，提升开发者对鸿蒙平台的理解与应用能力，掌握移动应用开发的核心技术，包括UI设计、数据存储、网络通信、用户认证等。同时培养团队协作能力和项目工程化意识。

---

## 2. 开发环境与技术栈

### 2.1 开发工具

| 工具 | 版本 | 用途 |
|------|------|------|
| DevEco Studio | 6.0.0+ | 鸿蒙应用开发IDE |
| Node.js | 18+ | 后端运行环境 |
| Git | - | 版本控制 |

### 2.2 操作系统

- **前端**：HarmonyOS 6.0.0+
- **后端**：跨平台（支持Windows、Linux、macOS）

### 2.3 编程语言与技术栈

**前端（ArkTS）**

- ArkTS是鸿蒙生态的编程语言，基于TypeScript扩展
- 支持声明式UI开发范式
- 类型安全，编译时检查

**后端（JavaScript/Node.js）**

- Express.js：Web框架
- sql.js：SQLite数据库（内存模式）
- JWT：用户认证
- bcryptjs：密码加密

### 2.4 数据库

- **本地**：SQLite（relationalStore API）
- **后端**：sql.js（内存SQLite）

### 2.5 主要依赖包

| 包名 | 用途 |
|------|------|
| @ohos/axios | HTTP客户端 |
| @ohos/mpchart | 图表库（饼图、柱状图、折线图） |
| relationalStore | 本地数据库 |
| dayjs | 日期格式化 |
| lunar | 农历日历 |

---

## 3. 功能设计

### 3.1 核心功能模块

本应用实现了以下主要功能：

#### 3.1.1 账单管理

- 添加、编辑、删除账单记录
- 支持选择账户、分类、金额、日期、备注
- 按日期范围筛选账单
- 账单列表展示与详情查看

#### 3.1.2 账户管理

- 创建多个账户（现金、银行卡、支付宝、微信等）
- 账户余额管理
- 账户间转账功能
- 账户汇总展示

#### 3.1.3 资产管理

- 记录固定资产（房产、车辆、电子设备等）
- 资产分类统计
- 资产变更记录

#### 3.1.4 预算管理

- 设置月度预算
- 预算进度跟踪
- 超预算提醒

#### 3.1.5 统计图表

- 消费结构饼图
- 收支趋势折线图
- 分类统计柱状图
- 月度报表生成

#### 3.1.6 用户认证

- 用户注册与登录
- 华为账号快捷登录
- JWT Token认证
- 刷新令牌机制

#### 3.1.7 云端同步

- 账单数据云端备份
- 多设备数据同步
- 离线数据缓存

### 3.2 功能流程图

```
用户 → 登录/注册 → 首页（账单列表）
                     ├─ 添加账单 ── 保存到本地/云端
                     ├─ 账户管理 ── 账户列表 ── 转账/余额
                     ├─ 统计图表 ── 选择时间 ── 查看报表
                     └─ 我的 ── 用户信息 ── 退出登录
```

---

## 4. 页面介绍

### 4.1 首页（home）

首页展示今日账单汇总和快速添加按钮。

**主要元素：**

- 顶部：月份选择器和筛选按钮
- 中部：今日/本周/本月支出卡片
- 列表区：账单记录列表，每条显示分类图标、备注、金额、日期
- 底部：Tab导航栏

**核心代码结构：**

```
features/home/src/main/ets/
├── views/
│   └── HomeView.ets      # 首页主视图
├── viewmodels/
│   └── HomeVM.ets        # 首页 ViewModel
└── model/
    └── HomeModel.ets     # 数据模型
```

### 4.2 登录页面（mine）

提供多种登录方式，支持用户账号和华为快捷登录。

**主要元素：**

- Logo和APP名称
- 用户名/密码输入框
- 华为账号登录按钮
- 注册新账号链接

**核心代码结构：**

```
features/mine/src/main/ets/
├── views/
│   ├── LoginPage.ets    # 登录页面
│   └── MineView.ets     # 我的页面
├── viewmodels/
│   ├── LoginVM.ets      # 登录 ViewModel
│   └── MineVM.ets       # 我的 ViewModel
└── model/
    └── UserModel.ets   # 用户模型
```

### 4.3 资产页面（assets）

展示用户资产概览和资产列表。

**主要元素：**

- 资产汇总卡片（总资产、净资产）
- 资产分类列表
- 添加资产按钮
- 资产详情页面

**核心代码结构：**

```
features/assets/src/main/ets/
├── views/
│   └── AssetsView.ets   # 资产页面
├── viewmodels/
│   └── AssetsVM.ets     # 资产 ViewModel
└── model/
    └── AssetsModel.ets # 资产模型
```

### 4.4 统计页面（statistics）

通过图表展示消费和收入统计。

**主要元素：**

- 时间范围选择器（月度/年度）
- 饼图：消费分类占比
- 折线图：收支趋势
- 柱状图：各分类金额对比

**核心代码结构：**

```
features/statistics/src/main/ets/
├── views/
│   └── StatisticsView.ets  # 统计页面
├── viewmodels/
│   └── StatisticsVM.ets    # 统计 ViewModel
└── model/
    └── StatisticsModel.ets # 统计模型
```

### 4.5 通用组件

项目封装的通用UI组件（components目录）：

| 组件 | 功能 |
|------|------|
| bill_card | 账单卡片组件 |
| bill_chart | 账单图表组件 |
| asset_card | 资产卡片组件 |
| asset_manage | 资产管理组件 |
| aggregated_login | 聚合登录组件 |
| bill_manage | 账单管理组件 |
| app_setting | 应用设置组件 |

---

## 5. 技术实现

### 5.1 架构设计

项目采用4层模块化架构：

```
products/entry      # 设备入口层（MainEntry.ets）
features/           # 功能模块层（home, assets, statistics, mine）
components/         # 通用组件层（bill_card, asset_manage等）
commons/            # 公共工具层（commonlib, lib_network）
```

### 5.2 数据库设计

本地数据库（SQLite）包含以下表：

| 表名 | 说明 |
|------|------|
| accounts | 账户表 |
| transactions | 账单/交易表 |
| assets | 资产表 |
| budgets | 预算表 |

数据库访问通过`AccountingDB`单例类实现：

```typescript
// bill_data_processing/src/main/ets/utils/accountingdb/
const accountingDB = new AccountingDB();
export { accountingDB };
```

### 5.3 网络层实现

HTTP请求封装在`lib_network`模块：

```typescript
// commons/lib_network/src/main/ets/https/Request.ets
class Request {
  async get(url: string, config?: RequestConfig): Promise<Response>
  async post(url: string, data: any, config?: RequestConfig): Promise<Response>
  async put(url: string, data: any, config?: RequestConfig): Promise<Response>
  async delete(url: string, config?: RequestConfig): Promise<Response>
}
```

API端点管理：

```typescript
// commons/lib_network/src/main/ets/https/apis/
Auth.ets    # 认证相关API
Sync.ets    # 同步相关API
```

### 5.4 后端API设计

后端采用RESTful API设计：

| 端点 | 方法 | 说明 |
|------|------|------|
| /api/auth/register | POST | 用户注册 |
| /api/auth/login | POST | 用户登录 |
| /api/auth/refresh | POST | 刷新令牌 |
| /api/sync/upload | POST | 上传数据 |
| /api/sync/download | GET | 下载数据 |

### 5.5 关键代码示例

**账单添加（HarmonyOS前端）**

```typescript
// 添加账单记录
async addTransaction(transaction: Transaction): Promise<void> {
  await accountingDB.transaction(async () => {
    await accountingDB.insert('transactions', transaction);
    // 更新账户余额
    const account = await accountingDB.findById('accounts', transaction.accountId);
    account.balance += transaction.type === 'expense' ? -transaction.amount : transaction.amount;
    await accountingDB.update('accounts', account);
  });
}
```

**JWT认证（Node.js后端）**

```javascript
// 生成访问令牌
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: '15m' });
};

// 生成刷新令牌
const generateRefreshToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_REFRESH_SECRET, { expiresIn: '7d' });
};
```

---

## 6. 挑战与解决方案

### 6.1 挑战一：鸿蒙数据库操作

**问题**：relationalStore API与Android SQLite API存在差异，需要适配。

**解决**：封装`BaseDB`基类，提供统一的CRUD接口，屏蔽底层差异。

### 6.2 挑战二：前后端数据同步

**问题**：离线数据与云端数据一致性维护。

**解决**：采用时间戳版本控制，每次修改记录版本号，冲突时以最新修改时间为准。

### 6.3 挑战三：华为快捷登录集成

**问题**：华为AGC认证流程复杂。

**解决**：通过`aggregated_login`组件封装登录逻辑，提供统一的登录接口。

### 6.4 挑战四：图表渲染性能

**问题**：大量账单数据渲染图表时性能下降。

**解决**：使用数据聚合预计算，配合mpchart的懒加载机制优化渲染。

---

## 7. 项目总结

### 7.1 成果

本项目成功实现了一个功能完善的HarmonyOS记账应用，主要成果包括：

1. 完成了4层模块化架构搭建
2. 实现了账单管理、账户管理、资产管理等核心功能
3. 开发了统计图表模块，支持多种图表展示
4. 搭建了Node.js后端服务，实现用户认证和数据同步API
5. 编写了完整的项目文档和报告

### 7.2 不足与改进

- 部分页面UI细节可以进一步优化
- 离线数据同步机制可以更加健壮
- 可以增加更多数据分析功能

### 7.3 心得

通过本次实训，我们深刻理解了移动应用开发的完整流程，掌握了鸿蒙平台开发的核心技术，提升了团队协作和项目工程化管理能力。

---

## 8. 格式要求说明

[以下为格式要求，请按此格式提交文档]{.mark}

- 1 一级标题：黑体四号
- 1.1 二级标题：宋体小四
- 1.1.1 三级标题：宋体小四
- 正文：宋体小四，首行缩进2字符
- 全文行距：固定值20磅

**提交的文档如果格式错乱将会被扣分！！！**

---

*注：请在提交前将文档中的"（请填写）"替换为实际信息*