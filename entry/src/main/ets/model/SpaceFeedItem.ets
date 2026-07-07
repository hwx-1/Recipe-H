/**
 * SpaceFeedItem - 空间动态
 */
export enum SpaceFeedType {
  SHARE = 'share',
  RECIPE_DONE = 'recipe_done',
  /** 双方行为记录（接取、取消、夸赞等） */
  TASK_ACTION = 'task_action'
}

export interface SpaceFeedItem {
  id: string;
  spaceId: string;
  feedType: SpaceFeedType;
  sharerId: string;
  sharerName: string;
  recipeId: string;
  recipeTitle: string;
  presetPhrase: string;
  photoUrl: string;
  createdAt: number;
  isRead: boolean;
}
