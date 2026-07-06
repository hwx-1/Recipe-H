/**
 * RecipeStats - 食谱全局统计数据模型
 *
 * 作用：描述单道食谱的转发量、点赞量，用于卡片展示与排行。
 * MVP 阶段存本地 Preferences，AGC Cloud DB 就绪后迁移为云端同步。
 */
export interface RecipeStats {
  recipeId: string;
  forwardCount: number;
  likeCount: number;
}
