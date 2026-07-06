/**
 * RecipeRepository - 食谱数据仓库
 *
 * 作用：从内置 rawfile(recipes.json)读取公开食谱并缓存，向上层提供只读查询能力。
 *      MVP 为纯本地数据源，后续可替换为云端而不影响调用方。
 */
import { util } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { Recipe } from '../model/Recipe';

/**
 * recipes.json 的顶层结构。
 */
interface RecipeFile {
  recipes: Recipe[];
}

export class RecipeRepository {
  private static instance: RecipeRepository | undefined = undefined;
  private cache: Recipe[] = [];
  private loaded: boolean = false;

  static getInstance(): RecipeRepository {
    if (RecipeRepository.instance === undefined) {
      RecipeRepository.instance = new RecipeRepository();
    }
    return RecipeRepository.instance;
  }

  /**
   * 首次调用时从 rawfile 同步读取并解析，之后走缓存。
   * @param context 用于获取 resourceManager 的上下文(getContext(this))
   */
  ensureLoaded(context: common.Context): void {
    if (this.loaded) {
      return;
    }
    const bytes: Uint8Array = context.resourceManager.getRawFileContentSync('recipes.json');
    const text: string = util.TextDecoder.create('utf-8').decodeToString(bytes);
    const parsed: RecipeFile = JSON.parse(text) as RecipeFile;
    this.cache = parsed.recipes.map((r: Recipe) => RecipeRepository.normalize(r));
    this.loaded = true;
  }

  private static normalize(recipe: Recipe): Recipe {
    if (recipe.emoji !== undefined && recipe.emoji.length > 0) {
      return recipe;
    }
    const emojiMap: Record<string, string> = {
      'r_tangcu_paigu': '🍖',
      'r_fanqie_chaodan': '🍅',
      'r_niupai': '🥩',
      'r_jixiong_shala': '🥗',
      'r_sanmingzhi': '🥪',
      'r_paigu_tang': '🍲',
      'r_mapo_doufu': '🌶️',
      'r_congyou_banmian': '🍜',
      'r_shufu_songbing': '🥐',
      'r_qingjiao_rousi': '🫑',
      'r_hongshao_rou': '🍖',
      'r_zhengdan': '🥚',
      'r_shousi_jiaozi': '🥟'
    };
    recipe.emoji = emojiMap[recipe.id] ?? '🍽️';
    return recipe;
  }

  /**
   * 全部食谱。
   */
  getAll(): Recipe[] {
    return this.cache;
  }

  /**
   * 按分类 ID 过滤。
   */
  getByCategory(categoryId: string): Recipe[] {
    return this.cache.filter((r: Recipe) => r.categories.includes(categoryId));
  }

  /**
   * 按 ID 查询单个食谱。
   */
  getById(id: string): Recipe | undefined {
    return this.cache.find((r: Recipe) => r.id === id);
  }
}
