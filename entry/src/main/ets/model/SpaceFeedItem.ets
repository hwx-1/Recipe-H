/**
 * SpaceFeedItem - 空间动态(食谱分享卡片)
 */
export interface SpaceFeedItem {
  id: string;
  spaceId: string;
  sharerId: string;
  sharerName: string;
  recipeId: string;
  recipeTitle: string;
  presetPhrase: string;
  createdAt: number;
  isRead: boolean;
}
