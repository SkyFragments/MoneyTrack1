import { AssetChangeType, TimeRangeType, AssetTrendItem } from 'asset_base';
import { BillPieChartItem } from 'bill_chart';
import { AssetProcessingModel } from 'bill_data_processing';
import { AccountingDB } from 'bill_data_processing';
import dayjs from 'dayjs';
import { LIABILITY_COLOR_LIST, NET_ASSET_COLOR_LIST } from '../commons/Constants';

@ObservedV2
export class AssetAnalysisVM {
  @Trace curType: AssetChangeType = AssetChangeType.NET_ASSET;
  @Trace assetProcessing: AssetProcessingModel = new AssetProcessingModel();
  @Trace timeRangeType: TimeRangeType = TimeRangeType.MONTH;
  @Trace trendData: AssetTrendItem[] = [];
  @Trace selectedAssetIds: Set<number> = new Set<number>();

  /**
   * 初始化数据
   */
  public async initData() {
    await this.assetProcessing.getAssetReport();
    // 默认选中所有账户
    const allAssets = [...this.assetProcessing.assetGroup.fund, ...this.assetProcessing.assetGroup.credit];
    this.selectedAssetIds = new Set(allAssets.map(a => a.assetId));
    await this.loadTrendData();
  }

  /**
   * 切换图表类型 (饼图：净资产/负债)
   */
  public changeType(type: AssetChangeType) {
    this.curType = type;
  }

  /**
   * 切换时间范围 (折线图：年/月)
   */
  public async changeTimeRangeType(type: TimeRangeType) {
    this.timeRangeType = type;
    await this.loadTrendData();
  }

  /**
   * 更新筛选账户
   */
  public async updateSelectedAssets(ids: Set<number>) {
    this.selectedAssetIds = ids;
    await this.loadTrendData();
  }

  /**
   * 加载折线图数据（倒推法）
   */
  public async loadTrendData() {
    const dates: string[] = [];
    const today = dayjs();

    if (this.timeRangeType === TimeRangeType.MONTH) {
      for (let i = 29; i >= 0; i--) {
        dates.push(today.subtract(i, 'day').format('YYYY-MM-DD'));
      }
    } else {
      for (let i = 11; i >= 0; i--) {
        dates.push(today.subtract(i, 'month').endOf('month').format('YYYY-MM-DD'));
      }
    }

    const currentBalances: Map<number, number> = new Map();
    const allAssets = [...this.assetProcessing.assetGroup.fund, ...this.assetProcessing.assetGroup.credit];

    const targetAssets = allAssets.filter(a => this.selectedAssetIds.has(a.assetId));
    targetAssets.forEach(asset => {
      currentBalances.set(asset.assetId, asset.amount);
    });

    if (targetAssets.length === 0) {
      this.trendData = dates.map(d => ({ date: d, value: 0 } as AssetTrendItem));
      return;
    }

    const resultData: AssetTrendItem[] = [];

    for (const dateStr of dates) {
      const impactRows = await AccountingDB.getTransactionImpactAfterDate(dateStr, Array.from(this.selectedAssetIds));
      const impactMap = new Map(impactRows.map(r => [r.assetId, r.impact]));
      let totalAssetAtDate = 0;
      targetAssets.forEach(asset => {
        const currentBalance = currentBalances.get(asset.assetId) ?? 0;
        const futureImpact = impactMap.get(asset.assetId) ?? 0;
        const pastBalance = currentBalance - futureImpact;
        totalAssetAtDate += pastBalance;
      });

      resultData.push({
        date: dateStr,
        value: totalAssetAtDate
      } as AssetTrendItem);
    }

    this.trendData = resultData;
  }

  @Computed
  public get pieChartData(): BillPieChartItem[] {
    const list: BillPieChartItem[] = [];
    const sourceList = this.curType === AssetChangeType.NET_ASSET
      ? this.assetProcessing.assetGroup.fund
      : this.assetProcessing.assetGroup.credit;

    if (!sourceList || sourceList.length === 0) {
      return [];
    }

    sourceList.forEach((item) => {
      const pieItem: BillPieChartItem = {
        label: item.name,
        value: this.curType === AssetChangeType.NET_ASSET ? item.amount : -item.amount,
        resource: item.subType
      };
      list.push(pieItem);
    });

    return list;
  }

  @Computed
  public get chartColors(): number[] {
    if (this.curType === AssetChangeType.NET_ASSET) {
      return NET_ASSET_COLOR_LIST;
    } else {
      return LIABILITY_COLOR_LIST;
    }
  }

  @Computed
  public get centerText(): string {
    if (this.curType === AssetChangeType.NET_ASSET) {
      return this.assetProcessing.assetSummary.totalAsset.toFixed(2);
    } else {
      return this.assetProcessing.assetSummary.totalLiability.toFixed(2);
    }
  }
}
