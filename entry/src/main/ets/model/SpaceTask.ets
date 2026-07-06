/**
 * SpaceTask - 情侣空间任务模型
 *
 * 作用：统一描述空间内各类待办(想吃/跑腿/食谱完成/每日约定/自定义)。
 */
export enum SpaceTaskType {
  CRAVING = 'craving',
  ERRAND = 'errand',
  RECIPE_DONE = 'recipe_done',
  DAILY_PACT = 'daily_pact',
  CUSTOM = 'custom'
}

export enum SpaceTaskStatus {
  OPEN = 'open',
  DOING = 'doing',
  DONE = 'done',
  PRAISED = 'praised'
}

export interface SpaceTask {
  id: string;
  spaceId: string;
  creatorId: string;
  assigneeId: string;
  type: SpaceTaskType;
  title: string;
  description: string;
  relatedRecipeId: string;
  status: SpaceTaskStatus;
  checkInPhotoUrl: string;
  praiseText: string;
  praisedBy: string;
  createdAt: number;
  updatedAt: number;
  isRead: boolean;
}
