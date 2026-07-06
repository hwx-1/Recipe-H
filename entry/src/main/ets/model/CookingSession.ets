/**
 * CookingSession - 烹饪会话模型
 *
 * 作用：记录一次“开始做”到“做完了”的过程。支持多道菜并行，每道菜按各自推荐时间独立计时。
 *      超时后触发提醒；完成后可生成 recipe_done 任务(待接入情侣空间)。
 */

/**
 * 会话状态。
 */
export enum CookingStatus {
  ACTIVE = 'active',
  COMPLETED = 'completed',
  ABANDONED = 'abandoned'
}

/**
 * 烹饪会话实体。
 */
export interface CookingSession {
  id: string;
  recipeId: string;
  recipeTitle: string;
  startTime: number;
  expectedEndTime: number;
  status: CookingStatus;
}
