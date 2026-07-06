/**
 * Recipe - 食谱数据模型
 *
 * 作用：描述一道公开食谱的完整信息，供食谱列表、详情、排行等场景复用。
 * 来源：MVP 阶段由内置 JSON(rawfile/recipes.json)读入，后续可切换云端。
 */

/**
 * 食材条目
 */
export interface Ingredient {
  name: string;
  amount: string;
}

/**
 * 烹饪步骤
 */
export interface RecipeStep {
  order: number;
  text: string;
  image?: string;
}

/**
 * 难度枚举
 */
export enum RecipeDifficulty {
  EASY = 'easy',
  MEDIUM = 'medium',
  HARD = 'hard'
}

/**
 * 食谱实体
 */
export interface Recipe {
  id: string;
  title: string;
  cover: string;
  emoji: string;
  tags: string[];
  categories: string[];
  timeMinutes: number;
  difficulty: RecipeDifficulty;
  servings: number;
  ingredients: Ingredient[];
  steps: RecipeStep[];
  tips?: string;
}
