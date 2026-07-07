/**
 * SpaceTask - 情侣空间任务模型
 */
export enum SpaceTaskType {
  CRAVING = 'craving',
  ERRAND = 'errand',
  RECIPE_FORWARD = 'recipe_forward',
  RECIPE_COOKING = 'recipe_cooking',
  RECIPE_DONE = 'recipe_done',
  DAILY_PACT = 'daily_pact',
  CUSTOM = 'custom'
}

export enum SpaceTaskStatus {
  OPEN = 'open',
  DOING = 'doing',
  /** 做完菜待上传打卡图，仅完成方可见 */
  PENDING_CHECKIN = 'pending_checkin',
  DONE = 'done',
  PRAISED = 'praised',
  CANCELLED = 'cancelled'
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
  /** 待办优先级：1 一级 / 2 二级 / 3 三级 */
  priority: number;
  checkInPhotoUrl: string;
  praiseText: string;
  praisedBy: string;
  createdAt: number;
  updatedAt: number;
  isRead: boolean;
}
