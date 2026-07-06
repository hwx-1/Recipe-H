/**
 * LikeRepository - 点赞数据仓库
 *
 * 作用：管理用户点赞的食谱 ID 集合，持久化于本地 Preferences。点赞与收藏是两个独立动作：
 *      点赞偏“喜欢/情侣可见”，收藏偏“稍后再做”。MVP 阶段为纯本地，后续可随账号云同步并计入全局排行。
 */
import { PrefsUtil } from '../common/PrefsUtil';
import { PrefKey } from '../common/Constants';

export class LikeRepository {
  private static instance: LikeRepository | undefined = undefined;
  private ids: Set<string> = new Set<string>();
  private loaded: boolean = false;

  static getInstance(): LikeRepository {
    if (LikeRepository.instance === undefined) {
      LikeRepository.instance = new LikeRepository();
    }
    return LikeRepository.instance;
  }

  private ensureLoaded(): void {
    if (this.loaded) {
      return;
    }
    const raw: string = PrefsUtil.getString(PrefKey.LIKE_IDS, '[]');
    const arr: string[] = JSON.parse(raw) as string[];
    this.ids = new Set<string>(arr);
    this.loaded = true;
  }

  private persist(): void {
    const arr: string[] = Array.from(this.ids);
    PrefsUtil.setString(PrefKey.LIKE_IDS, JSON.stringify(arr));
  }

  isLiked(id: string): boolean {
    this.ensureLoaded();
    return this.ids.has(id);
  }

  /**
   * 切换点赞状态，返回切换后是否已点赞。
   */
  toggle(id: string): boolean {
    this.ensureLoaded();
    if (this.ids.has(id)) {
      this.ids.delete(id);
    } else {
      this.ids.add(id);
    }
    this.persist();
    return this.ids.has(id);
  }

  getAllIds(): string[] {
    this.ensureLoaded();
    return Array.from(this.ids);
  }
}
