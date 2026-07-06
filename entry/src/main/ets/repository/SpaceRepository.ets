/**
 * SpaceRepository - 情侣空间数据仓库
 *
 * 作用：管理绑定、动态卡片、SpaceTask 的 CRUD 与未读计数。
 * MVP 使用 Preferences 本地持久化；接口与 AGC Cloud DB 对象对齐，后续可替换实现。
 */
import { util } from '@kit.ArkTS';
import { PrefsUtil } from '../common/PrefsUtil';
import { PrefKey, AppConst } from '../common/Constants';
import { CoupleSpace, PendingInvite } from '../model/CoupleSpace';
import { SpaceFeedItem } from '../model/SpaceFeedItem';
import { SpaceTask, SpaceTaskStatus, SpaceTaskType } from '../model/SpaceTask';
import { LocalUserIds } from '../service/LocalUserService';

export const SPACE_VERSION: string = 'spaceVersion';
export const KEY_SPACE_BOUND: string = 'isSpaceBound';

interface SpaceStore {
  space: CoupleSpace | null;
  invite: PendingInvite | null;
  feeds: SpaceFeedItem[];
  tasks: SpaceTask[];
}

export class SpaceRepository {
  private static instance: SpaceRepository | undefined = undefined;
  private store: SpaceStore = { space: null, invite: null, feeds: [], tasks: [] };
  private loaded: boolean = false;

  static getInstance(): SpaceRepository {
    if (SpaceRepository.instance === undefined) {
      SpaceRepository.instance = new SpaceRepository();
    }
    return SpaceRepository.instance;
  }

  initStorage(): void {
    AppStorage.setOrCreate(SPACE_VERSION, 0);
    AppStorage.setOrCreate(KEY_SPACE_BOUND, false);
  }

  /**
   * 本地演示：自动创建「我 + TA」情侣空间，无需登录与邀请码。
   */
  ensureLocalCoupleSpace(): void {
    this.ensureLoaded();
    if (this.isBound()) {
      return;
    }
    this.store.space = {
      id: 'space_local',
      memberIds: [LocalUserIds.SELF, LocalUserIds.PARTNER],
      memberNames: [LocalUserIds.SELF_NAME, LocalUserIds.PARTNER_NAME],
      status: 'active',
      boundAt: Date.now()
    };
    this.bump();
  }

  private ensureLoaded(): void {
    if (this.loaded) {
      return;
    }
    const raw: string = PrefsUtil.getString(PrefKey.SPACE_DATA, '');
    if (raw.length > 0) {
      this.store = JSON.parse(raw) as SpaceStore;
      this.migrateSpaceFields();
    }
    this.loaded = true;
    this.syncBoundFlag();
  }

  /** 兼容旧版本本地数据 */
  private migrateSpaceFields(): void {
    if (this.store.space !== null) {
      if (this.store.space.memberNames === undefined) {
        this.store.space.memberNames = ['', ''];
      }
      if (this.store.space.boundAt === undefined) {
        this.store.space.boundAt = 0;
      }
    }
    this.store.feeds.forEach((f: SpaceFeedItem) => {
      if (f.sharerName === undefined) {
        f.sharerName = '';
      }
    });
  }

  private persist(): void {
    PrefsUtil.setString(PrefKey.SPACE_DATA, JSON.stringify(this.store));
    const ver: number = (AppStorage.get<number>(SPACE_VERSION) ?? 0) + 1;
    AppStorage.setOrCreate(SPACE_VERSION, ver);
    this.syncBoundFlag();
  }

  private syncBoundFlag(): void {
    const bound: boolean = this.store.space !== null && this.store.space.memberIds.length >= 2;
    AppStorage.setOrCreate(KEY_SPACE_BOUND, bound);
  }

  private bump(): void {
    this.persist();
  }

  isBound(): boolean {
    this.ensureLoaded();
    return this.store.space !== null && this.store.space.memberIds.length >= 2;
  }

  getSpace(): CoupleSpace | undefined {
    this.ensureLoaded();
    return this.store.space ?? undefined;
  }

  getPartnerId(userId: string): string {
    const space: CoupleSpace | undefined = this.getSpace();
    if (space === undefined) {
      return '';
    }
    if (space.memberIds[0] === userId) {
      return space.memberIds.length > 1 ? space.memberIds[1] : '';
    }
    return space.memberIds[0];
  }

  getPartnerName(userId: string): string {
    const space: CoupleSpace | undefined = this.getSpace();
    if (space === undefined || space.memberNames === undefined) {
      return 'TA';
    }
    if (space.memberIds[0] === userId) {
      return space.memberNames.length > 1 && space.memberNames[1].length > 0 ?
        space.memberNames[1] : 'TA';
    }
    return space.memberNames.length > 0 && space.memberNames[0].length > 0 ?
      space.memberNames[0] : 'TA';
  }

  getBoundDays(): number {
    const space: CoupleSpace | undefined = this.getSpace();
    if (space === undefined || space.boundAt <= 0) {
      return 0;
    }
    return Math.max(1, Math.floor((Date.now() - space.boundAt) / (24 * 3600 * 1000)));
  }

  /**
   * 解绑情侣空间：清除本机空间数据（云端接入后可改为归档）。
   */
  unbind(_userId: string): void {
    this.ensureLoaded();
    this.store.space = null;
    this.store.invite = null;
    this.store.feeds = [];
    this.store.tasks = [];
    this.bump();
  }

  getCompletedTaskCount(userId: string): number {
    return this.getTasks().filter((t: SpaceTask) =>
      t.status === SpaceTaskStatus.PRAISED &&
      (t.creatorId === userId || t.assigneeId === userId || t.praisedBy === userId)
    ).length;
  }

  attachCheckInPhoto(taskId: string, photoUrl: string): void {
    this.ensureLoaded();
    const task: SpaceTask | undefined = this.getTaskById(taskId);
    if (task !== undefined) {
      task.checkInPhotoUrl = photoUrl;
      task.updatedAt = Date.now();
      this.bump();
    }
  }

  /**
   * 生成邀请码(7 天有效)。
   */
  generateInviteCode(creatorId: string, creatorName: string): string {
    this.ensureLoaded();
    const num: number = Math.floor(1000 + Math.random() * 9000);
    const code: string = `LOVE-${num}`;
    const expiresAt: number = Date.now() + AppConst.INVITE_CODE_VALID_DAYS * 24 * 3600 * 1000;
    this.store.invite = { code: code, creatorId: creatorId, creatorName: creatorName, expiresAt: expiresAt };
    if (this.store.space === null) {
      this.store.space = {
        id: `space_${creatorId}`,
        memberIds: [creatorId],
        memberNames: [creatorName, ''],
        status: 'pending',
        boundAt: 0
      };
    } else if (this.store.space.memberNames.length === 0) {
      this.store.space.memberNames = [creatorName, ''];
    }
    this.bump();
    return code;
  }

  getMyInviteCode(): string {
    this.ensureLoaded();
    if (this.store.invite === null) {
      return '';
    }
    if (Date.now() > this.store.invite.expiresAt) {
      return '';
    }
    return this.store.invite.code;
  }

  /**
   * 输入邀请码完成绑定。
   */
  bindWithCode(code: string, userId: string, userName: string): string {
    this.ensureLoaded();
    if (this.store.invite === null) {
      return '邀请码不存在或已过期';
    }
    if (Date.now() > this.store.invite.expiresAt) {
      return '邀请码已过期，请让对方重新生成';
    }
    if (this.store.invite.code.toUpperCase() !== code.trim().toUpperCase()) {
      return '邀请码不正确';
    }
    if (this.store.invite.creatorId === userId) {
      return '不能绑定自己的邀请码';
    }
    if (this.store.space === null) {
      return '空间数据异常';
    }
    this.store.space.memberIds = [this.store.invite.creatorId, userId];
    this.store.space.memberNames = [this.store.invite.creatorName, userName];
    this.store.space.status = 'active';
    this.store.space.boundAt = Date.now();
    this.store.invite = null;
    this.bump();
    return '';
  }

  getFeedItems(): SpaceFeedItem[] {
    this.ensureLoaded();
    return [...this.store.feeds].sort((a: SpaceFeedItem, b: SpaceFeedItem) => b.createdAt - a.createdAt);
  }

  addFeedShare(recipeId: string, recipeTitle: string, phrase: string, sharerId: string,
    sharerName: string): void {
    this.ensureLoaded();
    if (!this.isBound() || this.store.space === null) {
      return;
    }
    const item: SpaceFeedItem = {
      id: `feed_${util.generateRandomUUID()}`,
      spaceId: this.store.space.id,
      sharerId: sharerId,
      sharerName: sharerName.length > 0 ? sharerName : '我',
      recipeId: recipeId,
      recipeTitle: recipeTitle,
      presetPhrase: phrase,
      createdAt: Date.now(),
      isRead: false
    };
    this.store.feeds.unshift(item);
    this.bump();
  }

  getTasks(): SpaceTask[] {
    this.ensureLoaded();
    return [...this.store.tasks].sort((a: SpaceTask, b: SpaceTask) => b.updatedAt - a.updatedAt);
  }

  getActiveTasks(): SpaceTask[] {
    return this.getTasks().filter((t: SpaceTask) => t.status !== SpaceTaskStatus.PRAISED);
  }

  getOpenTasks(): SpaceTask[] {
    return this.getTasks().filter((t: SpaceTask) =>
      t.status === SpaceTaskStatus.OPEN || t.status === SpaceTaskStatus.DOING);
  }

  getTaskById(id: string): SpaceTask | undefined {
    return this.getTasks().find((t: SpaceTask) => t.id === id);
  }

  createTask(type: SpaceTaskType, title: string, creatorId: string, description: string,
    relatedRecipeId: string): SpaceTask {
    this.ensureLoaded();
    const space: CoupleSpace = this.store.space!;
    const task: SpaceTask = {
      id: `task_${util.generateRandomUUID()}`,
      spaceId: space.id,
      creatorId: creatorId,
      assigneeId: '',
      type: type,
      title: title,
      description: description,
      relatedRecipeId: relatedRecipeId,
      status: SpaceTaskStatus.OPEN,
      checkInPhotoUrl: '',
      praiseText: '',
      praisedBy: '',
      createdAt: Date.now(),
      updatedAt: Date.now(),
      isRead: false
    };
    this.store.tasks.unshift(task);
    this.bump();
    return task;
  }

  createRecipeDoneTask(recipeId: string, title: string, userId: string): SpaceTask {
    const task: SpaceTask = this.createTask(SpaceTaskType.RECIPE_DONE, `完成了：${title}`, userId, '', recipeId);
    task.assigneeId = userId;
    task.status = SpaceTaskStatus.DONE;
    task.isRead = false;
    this.bump();
    return task;
  }

  acceptTask(taskId: string, userId: string): void {
    this.ensureLoaded();
    const task: SpaceTask | undefined = this.getTaskById(taskId);
    if (task === undefined || task.status !== SpaceTaskStatus.OPEN) {
      return;
    }
    task.assigneeId = userId;
    task.status = SpaceTaskStatus.DOING;
    task.updatedAt = Date.now();
    this.bump();
  }

  completeTask(taskId: string, userId: string): void {
    this.ensureLoaded();
    const task: SpaceTask | undefined = this.getTaskById(taskId);
    if (task === undefined) {
      return;
    }
    task.status = SpaceTaskStatus.DONE;
    task.updatedAt = Date.now();
    task.isRead = false;
    this.bump();
  }

  praiseTask(taskId: string, userId: string, phrase: string): void {
    this.ensureLoaded();
    const task: SpaceTask | undefined = this.getTaskById(taskId);
    if (task === undefined || task.status !== SpaceTaskStatus.DONE) {
      return;
    }
    if (task.creatorId === userId && task.assigneeId === userId) {
      return;
    }
    task.praiseText = phrase;
    task.praisedBy = userId;
    task.status = SpaceTaskStatus.PRAISED;
    task.updatedAt = Date.now();
    task.isRead = false;
    this.bump();
  }

  markFeedRead(feedId: string): void {
    this.ensureLoaded();
    const feed: SpaceFeedItem | undefined = this.store.feeds.find((f: SpaceFeedItem) => f.id === feedId);
    if (feed !== undefined) {
      feed.isRead = true;
      this.bump();
    }
  }

  markTaskRead(taskId: string): void {
    this.ensureLoaded();
    const task: SpaceTask | undefined = this.getTaskById(taskId);
    if (task !== undefined) {
      task.isRead = true;
      this.bump();
    }
  }

  getUnreadCount(userId: string): number {
    this.ensureLoaded();
    if (!this.isBound()) {
      return 0;
    }
    let count: number = 0;
    this.store.feeds.forEach((f: SpaceFeedItem) => {
      if (!f.isRead && f.sharerId !== userId) {
        count += 1;
      }
    });
    this.store.tasks.forEach((t: SpaceTask) => {
      if (!t.isRead && t.creatorId !== userId && t.status === SpaceTaskStatus.DONE) {
        count += 1;
      }
      if (!t.isRead && t.creatorId === userId && t.status === SpaceTaskStatus.PRAISED) {
        count += 1;
      }
      if (!t.isRead && t.creatorId !== userId &&
        (t.status === SpaceTaskStatus.OPEN || t.status === SpaceTaskStatus.DOING)) {
        count += 1;
      }
    });
    return count;
  }
}
