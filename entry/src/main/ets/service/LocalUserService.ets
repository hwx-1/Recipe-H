/**
 * LocalUserService - 本地小空间用户身份
 *
 * 作用：本地演示阶段固定为「我」的视角，无需切换双方身份。
 */
export class LocalUserIds {
  static readonly SELF: string = 'local_self';
  static readonly PARTNER: string = 'local_partner';
  static readonly SELF_NAME: string = '我';
  static readonly PARTNER_NAME: string = 'TA';
}

export class LocalUserService {
  static initStorage(): void {
    // 预留：后续接入华为账号后可在此写入真实 UnionID
  }

  static getSelfId(): string {
    return LocalUserIds.SELF;
  }

  static getSelfName(): string {
    return LocalUserIds.SELF_NAME;
  }

  static getActiveUserId(): string {
    return LocalUserIds.SELF;
  }

  static getActiveUserName(): string {
    return LocalUserIds.SELF_NAME;
  }
}
