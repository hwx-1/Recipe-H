/**
 * CoupleSpace - 情侣空间与邀请码
 */
export interface CoupleSpace {
  id: string;
  memberIds: string[];
  memberNames: string[];
  status: string;
  boundAt: number;
}

export interface PendingInvite {
  code: string;
  creatorId: string;
  creatorName: string;
  expiresAt: number;
}
