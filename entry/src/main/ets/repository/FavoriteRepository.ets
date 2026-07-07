/**
 * FavoriteRepository - 收藏数据仓库
 *
 * 作用：管理用户收藏的食谱 ID 集合，持久化于本地 Preferences(以 JSON 数组字符串存储)。
 *      MVP 阶段为纯本地，无需登录；后续可迁移为随账号云同步。
 */
import { PrefsUtil } from '../common/PrefsUtil';
import { PrefKey } from '../common/Constants';

/** AppStorage 键：收藏变更版本号 */
export const FAVORITE_VERSION: string = 'favoriteVersion';

export class FavoriteRepository {
  private static instance: FavoriteRepository | undefined = undefined;
  private ids: Set<string> = new Set<string>();
  private loaded: boolean = false;

  static getInstance(): FavoriteRepository {
    if (FavoriteRepository.instance === undefined) {
      FavoriteRepository.instance = new FavoriteRepository();
    }
    return FavoriteRepository.instance;
  }

  initStorage(): void {
    AppStorage.setOrCreate(FAVORITE_VERSION, 0);
  }

  private ensureLoaded(): void {
    if (this.loaded) {
      return;
    }
    const raw: string = PrefsUtil.getString(PrefKey.FAVORITE_IDS, '[]');
    const arr: string[] = JSON.parse(raw) as string[];
    this.ids = new Set<string>(arr);
    this.loaded = true;
  }

  private persist(): void {
    const arr: string[] = Array.from(this.ids);
    PrefsUtil.setString(PrefKey.FAVORITE_IDS, JSON.stringify(arr));
    const ver: number = (AppStorage.get<number>(FAVORITE_VERSION) ?? 0) + 1;
    AppStorage.setOrCreate(FAVORITE_VERSION, ver);
  }

  isFavorite(id: string): boolean {
    this.ensureLoaded();
    return this.ids.has(id);
  }

  /**
   * 切换收藏状态，返回切换后的是否已收藏。
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

  /**
   * 全部收藏的食谱 ID。
   */
  getAllIds(): string[] {
    this.ensureLoaded();
    return Array.from(this.ids);
  }
}
