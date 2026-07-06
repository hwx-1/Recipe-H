/**
 * RecipeCategory - 食谱分类模型与常量
 *
 * 作用：定义首页 13 个场景分类入口的元数据(ID、展示名、图标、主题色)。
 * 复用：CategoryGrid、RecipeListPage 标题、分类筛选。
 */

/**
 * 分类实体
 */
export interface RecipeCategory {
  id: string;
  name: string;
  emoji: string;
  color: string;
}

/**
 * MVP 13 个场景分类(一菜可归属多个)。
 */
export const RECIPE_CATEGORIES: RecipeCategory[] = [
  { id: 'candlelight', name: '烛光晚餐', emoji: '🕯️', color: '#FFB3C1' },
  { id: 'simple_two', name: '两人简餐', emoji: '🍳', color: '#FFD3A5' },
  { id: 'big_dish', name: '大菜硬菜', emoji: '🍖', color: '#F6A6A6' },
  { id: 'light_food', name: '减脂轻食', emoji: '🥗', color: '#A8E6B0' },
  { id: 'breakfast', name: '元气早餐', emoji: '🥪', color: '#FFE08A' },
  { id: 'soup', name: '汤羹暖锅', emoji: '🍲', color: '#FFC1A6' },
  { id: 'vegetarian', name: '素食蔬食', emoji: '🥦', color: '#B7E4A0' },
  { id: 'noodle_staple', name: '主食面点', emoji: '🍜', color: '#FFD98A' },
  { id: 'snack_dessert', name: '小食甜点', emoji: '🧁', color: '#FFC2E2' },
  { id: 'quick_15', name: '15分钟快手', emoji: '⏱️', color: '#A6D8FF' },
  { id: 'night_snack', name: '深夜食堂', emoji: '🌙', color: '#C4B5FF' },
  { id: 'bento', name: '便当日常', emoji: '🍱', color: '#FFB6A0' },
  { id: 'festival', name: '节日特辑', emoji: '🎉', color: '#FF9EB5' }
];

/**
 * 根据分类 ID 查找展示名，未命中返回原 ID。
 */
export function categoryNameById(id: string): string {
  const found: RecipeCategory | undefined = RECIPE_CATEGORIES.find((c: RecipeCategory) => c.id === id);
  return found !== undefined ? found.name : id;
}
