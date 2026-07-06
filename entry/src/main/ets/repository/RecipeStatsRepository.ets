/**
 * RecipeStatsRepository - 食谱全局统计仓库
 *
 * 作用：管理每道食谱的转发量/点赞量(本地持久化)，并通过 AppStorage 广播变更以实现 UI 实时更新。
 *      点赞与 LikeRepository 联动；转发在详情页确认后累加。
 * MVP 后替换为 AGC Cloud DB 读写，接口保持不变。
 */
import { PrefsUtil } from '../common/PrefsUtil';
import { PrefKey } from '../common/Constants';
import { RecipeStats } from '../model/RecipeStats';

/** AppStorage 键：统计版本号，变更时触发卡片/列表重绘 */
export const RECIPE_STATS_VERSION: string = 'recipeStatsVersion';

export class RecipeStatsRepository {
  private static instance: RecipeStatsRepository | undefined = undefined;
  private cache: Map<string, RecipeStats> = new Map<string, RecipeStats>();
  private loaded: boolean = false;

  static getInstance(): RecipeStatsRepository {
    if (RecipeStatsRepository.instance === undefined) {
      RecipeStatsRepository.instance = new RecipeStatsRepository();
    }
    return RecipeStatsRepository.instance;
  }

  private ensureLoaded(): void {
    if (this.loaded) {
      return;
    }
    const raw: string = PrefsUtil.getString(PrefKey.RECIPE_STATS, '[]');
    const parsed: RecipeStats[] = JSON.parse(raw) as RecipeStats[];
    parsed.forEach((stats: RecipeStats) => {
      this.cache.set(stats.recipeId, stats);
    });
    this.loaded = true;
    AppStorage.setOrCreate(RECIPE_STATS_VERSION, 0);
  }

  private persist(): void {
    const arr: RecipeStats[] = [];
    this.cache.forEach((stats: RecipeStats) => {
      arr.push(stats);
    });
    PrefsUtil.setString(PrefKey.RECIPE_STATS, JSON.stringify(arr));
    const ver: number = (AppStorage.get<number>(RECIPE_STATS_VERSION) ?? 0) + 1;
    AppStorage.setOrCreate(RECIPE_STATS_VERSION, ver);
  }

  private ensureEntry(recipeId: string): RecipeStats {
    let stats: RecipeStats | undefined = this.cache.get(recipeId);
    if (stats === undefined) {
      stats = { recipeId: recipeId, forwardCount: 0, likeCount: 0 };
      this.cache.set(recipeId, stats);
    }
    return stats;
  }

  getStats(recipeId: string): RecipeStats {
    this.ensureLoaded();
    const stats: RecipeStats | undefined = this.cache.get(recipeId);
    if (stats === undefined) {
      return { recipeId: recipeId, forwardCount: 0, likeCount: 0 };
    }
    return stats;
  }

  /**
   * 点赞状态变更后同步全局点赞数（+1 或 -1，不低于 0）。
   */
  applyLikeChange(recipeId: string, isLiked: boolean, wasLiked: boolean): void {
    this.ensureLoaded();
    if (isLiked === wasLiked) {
      return;
    }
    const stats: RecipeStats = this.ensureEntry(recipeId);
    if (isLiked) {
      stats.likeCount += 1;
    } else if (stats.likeCount > 0) {
      stats.likeCount -= 1;
    }
    this.persist();
  }

  /**
   * 转发到空间成功后累加转发量。
   */
  addForward(recipeId: string): void {
    this.ensureLoaded();
    const stats: RecipeStats = this.ensureEntry(recipeId);
    stats.forwardCount += 1;
    this.persist();
  }

  /**
   * 按转发量降序返回 recipeId 列表。
   */
  rankByForward(allIds: string[]): string[] {
    this.ensureLoaded();
    const sorted: string[] = [...allIds];
    sorted.sort((a: string, b: string) => {
      return this.getStats(b).forwardCount - this.getStats(a).forwardCount;
    });
    return sorted;
  }

  /**
   * 按点赞量降序返回 recipeId 列表。
   */
  rankByLike(allIds: string[]): string[] {
    this.ensureLoaded();
    const sorted: string[] = [...allIds];
    sorted.sort((a: string, b: string) => {
      return this.getStats(b).likeCount - this.getStats(a).likeCount;
    });
    return sorted;
  }

  /** 强制刷新广播（下拉刷新时调用） */
  bumpVersion(): void {
    this.ensureLoaded();
    const ver: number = (AppStorage.get<number>(RECIPE_STATS_VERSION) ?? 0) + 1;
    AppStorage.setOrCreate(RECIPE_STATS_VERSION, ver);
  }
}
