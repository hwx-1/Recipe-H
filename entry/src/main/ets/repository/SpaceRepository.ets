/**
 * SpaceRepository - 情侣空间数据仓库
 */
import { util } from '@kit.ArkTS';
import { PrefsUtil } from '../common/PrefsUtil';
import { PrefKey, AppConst } from '../common/Constants';
import { CoupleSpace, PendingInvite } from '../model/CoupleSpace';
import { SpaceFeedItem, SpaceFeedType } from '../model/SpaceFeedItem';
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
      if (f.feedType === undefined) {
        f.feedType = SpaceFeedType.SHARE;
      }
      if (f.photoUrl === undefined) {
        f.photoUrl = '';
      }
    });
    this.store.tasks.forEach((t: SpaceTask) => {
      if (t.priority === undefined || t.priority < 1 || t.priority > 3) {
        t.priority = 2;
      }
      if (t.praiseText === undefined) {
        t.praiseText = '';
      }
      if (t.praisedBy === undefined) {
        t.praisedBy = '';
      }
      if (t.checkInPhotoUrl === undefined) {
        t.checkInPhotoUrl = '';
      }
    });
  }

  private compareTasks(a: SpaceTask, b: SpaceTask): number {
    if (a.priority !== b.priority) {
      return a.priority - b.priority;
    }
    return a.createdAt - b.createdAt;
  }

  getTaskStatusLabel(task: SpaceTask, viewerId: string): string {
    if (task.status === SpaceTaskStatus.OPEN) {
      return '待接取';
    }
    if (task.status === SpaceTaskStatus.DOING) {
      if (task.assigneeId === viewerId) {
        return '我已接取';
      }
      if (task.assigneeId.length > 0) {
        return '对方已接取';
      }
      return '进行中';
    }
    if (task.status === SpaceTaskStatus.PENDING_CHECKIN) {
      return '待打卡';
    }
    if (task.status === SpaceTaskStatus.DONE) {
      return '待夸赞';
    }
    if (task.status === SpaceTaskStatus.PRAISED) {
      return '已完成';
    }
    return '已取消';
  }

  private insertFeed(item: SpaceFeedItem): void {
    this.store.feeds.unshift(item);
  }

  addFeedAction(actorId: string, actorName: string, title: string, phrase: string,
    relatedId: string): void {
    this.ensureLoaded();
    if (!this.isBound() || this.store.space === null) {
      return;
    }
    const item: SpaceFeedItem = {
      id: `feed_${util.generateRandomUUID()}`,
      spaceId: this.store.space.id,
      feedType: SpaceFeedType.TASK_ACTION,
      sharerId: actorId,
      sharerName: actorName.length > 0 ? actorName : '我',
      recipeId: relatedId,
      recipeTitle: title,
      presetPhrase: phrase,
      photoUrl: '',
      createdAt: Date.now(),
      isRead: false
    };
    this.insertFeed(item);
  }

  private actorPhrase(actorId: string, actorName: string, viewerId: string, verb: string): string {
    if (actorId === viewerId) {
      return `我${verb}`;
    }
    const name: string = actorName.length > 0 ? actorName : 'TA';
    return `${name}${verb}`;
  }

  getFeedActionLabel(item: SpaceFeedItem, viewerId: string): string {
    const actor: string = this.actorPhrase(item.sharerId, item.sharerName, viewerId, '');
    return `${actor}${item.presetPhrase}：${item.recipeTitle}`;
  }

  formatFeedDate(timestamp: number): string {
    const d: Date = new Date(timestamp);
    const month: number = d.getMonth() + 1;
    const day: number = d.getDate();
    const weekdays: string[] = ['日', '一', '二', '三', '四', '五', '六'];
    return `${month}月${day}日 周${weekdays[d.getDay()]}`;
  }

  isSameDay(ts1: number, ts2: number): boolean {
    const d1: Date = new Date(ts1);
    const d2: Date = new Date(ts2);
    return d1.getFullYear() === d2.getFullYear() &&
      d1.getMonth() === d2.getMonth() &&
      d1.getDate() === d2.getDate();
  }

  getAllFeedItems(): SpaceFeedItem[] {
    this.ensureLoaded();
    return [...this.store.feeds].sort((a: SpaceFeedItem, b: SpaceFeedItem) => b.createdAt - a.createdAt);
  }

  getFeedPreview(limit: number): SpaceFeedItem[] {
    return this.getAllFeedItems().slice(0, limit);
  }

  getFeedItems(): SpaceFeedItem[] {
    return this.getAllFeedItems();
  }

  filterFeedsByDate(feeds: SpaceFeedItem[], mode: string): SpaceFeedItem[] {
    const todayStart: number = new Date().setHours(0, 0, 0, 0);
    const oneDay: number = 24 * 3600 * 1000;
    if (mode === 'today') {
      return feeds.filter((f: SpaceFeedItem) => f.createdAt >= todayStart);
    }
    if (mode === 'yesterday') {
      const yesterdayStart: number = todayStart - oneDay;
      return feeds.filter((f: SpaceFeedItem) =>
        f.createdAt >= yesterdayStart && f.createdAt < todayStart);
    }
    if (mode === 'recent3') {
      const threeDaysStart: number = todayStart - 2 * oneDay;
      return feeds.filter((f: SpaceFeedItem) => f.createdAt >= threeDaysStart);
    }
    return feeds.filter((f: SpaceFeedItem) => f.createdAt >= todayStart);
  }

  isVisibleToUser(task: SpaceTask, userId: string): boolean {
    if (task.status === SpaceTaskStatus.PRAISED || task.status === SpaceTaskStatus.CANCELLED) {
      return false;
    }
    if (task.status === SpaceTaskStatus.PENDING_CHECKIN) {
      return task.assigneeId === userId;
    }
    if (task.status === SpaceTaskStatus.DONE) {
      return task.assigneeId !== userId;
    }
    return true;
  }

  private findCookingTask(recipeId: string, userId: string,
    statuses: SpaceTaskStatus[]): SpaceTask | undefined {
    this.ensureLoaded();
    return this.store.tasks.find((t: SpaceTask) =>
      t.relatedRecipeId === recipeId &&
      (t.type === SpaceTaskType.RECIPE_COOKING || t.type === SpaceTaskType.RECIPE_DONE) &&
      t.assigneeId === userId &&
      statuses.includes(t.status));
  }

  isCookingRecipe(recipeId: string, userId: string): boolean {
    return this.findCookingTask(recipeId, userId, [SpaceTaskStatus.DOING]) !== undefined;
  }

  isPendingCheckInRecipe(recipeId: string, userId: string): boolean {
    return this.findCookingTask(recipeId, userId, [SpaceTaskStatus.PENDING_CHECKIN]) !== undefined;
  }

  startCookingTask(recipeId: string, title: string, userId: string, userName: string = ''): SpaceTask {
    this.ensureLoaded();
    const existing: SpaceTask | undefined = this.findCookingTask(recipeId, userId,
      [SpaceTaskStatus.DOING, SpaceTaskStatus.PENDING_CHECKIN]);
    if (existing !== undefined) {
      return existing;
    }
    const forward: SpaceTask | undefined = this.store.tasks.find((t: SpaceTask) =>
      t.relatedRecipeId === recipeId &&
      t.type === SpaceTaskType.RECIPE_FORWARD &&
      (t.status === SpaceTaskStatus.OPEN || t.status === SpaceTaskStatus.DOING) &&
      (t.assigneeId === userId || (t.assigneeId.length === 0 && t.creatorId === userId)));
    if (forward !== undefined) {
      forward.type = SpaceTaskType.RECIPE_COOKING;
      forward.title = `制作中：${title}`;
      forward.assigneeId = userId;
      forward.status = SpaceTaskStatus.DOING;
      forward.updatedAt = Date.now();
      forward.isRead = false;
      if (userName.length > 0) {
        this.addFeedAction(userId, userName, forward.title, '开始制作', recipeId);
      }
      this.bump();
      return forward;
    }
    const task: SpaceTask = this.createTask(SpaceTaskType.RECIPE_COOKING, `制作中：${title}`, userId, '',
      recipeId, 2);
    task.assigneeId = userId;
    task.status = SpaceTaskStatus.DOING;
    task.isRead = false;
    if (userName.length > 0) {
      this.addFeedAction(userId, userName, task.title, '开始制作', recipeId);
    }
    this.bump();
    return task;
  }

  markCookingPendingCheckIn(recipeId: string, title: string, userId: string,
    userName: string = ''): boolean {
    this.ensureLoaded();
    const task: SpaceTask | undefined = this.findCookingTask(recipeId, userId, [SpaceTaskStatus.DOING]);
    if (task === undefined) {
      return false;
    }
    task.status = SpaceTaskStatus.PENDING_CHECKIN;
    task.title = `待打卡：${title}`;
    task.updatedAt = Date.now();
    task.isRead = false;
    if (userName.length > 0) {
      this.addFeedAction(userId, userName, task.title, '做完了，待上传打卡', recipeId);
    }
    this.bump();
    return true;
  }

  cancelCookingTask(recipeId: string, userId: string, userName: string = ''): void {
    this.ensureLoaded();
    const task: SpaceTask | undefined = this.findCookingTask(recipeId, userId, [SpaceTaskStatus.DOING]);
    if (task === undefined) {
      return;
    }
    this.abandonTask(task.id, userId, userName);
  }

  getPendingCheckInTasks(userId: string): SpaceTask[] {
    this.ensureLoaded();
    return this.store.tasks
      .filter((t: SpaceTask) =>
        t.status === SpaceTaskStatus.PENDING_CHECKIN && t.assigneeId === userId)
      .sort((a: SpaceTask, b: SpaceTask) => b.updatedAt - a.updatedAt);
  }

  getCookCompletedCount(): number {
    return PrefsUtil.getNumber(PrefKey.COOKING_COMPLETED_COUNT, 0);
  }

  private incrementCookCompletedCount(): void {
    PrefsUtil.setNumber(PrefKey.COOKING_COMPLETED_COUNT, this.getCookCompletedCount() + 1);
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

  addFeedComplete(recipeId: string, recipeTitle: string, phrase: string, photoUrl: string,
    sharerId: string, sharerName: string): void {
    this.ensureLoaded();
    if (!this.isBound() || this.store.space === null) {
      return;
    }
    const item: SpaceFeedItem = {
      id: `feed_${util.generateRandomUUID()}`,
      spaceId: this.store.space.id,
      feedType: SpaceFeedType.RECIPE_DONE,
      sharerId: sharerId,
      sharerName: sharerName.length > 0 ? sharerName : '我',
      recipeId: recipeId,
      recipeTitle: recipeTitle,
      presetPhrase: phrase,
      photoUrl: photoUrl,
      createdAt: Date.now(),
      isRead: false
    };
    this.store.feeds.unshift(item);
    this.bump();
  }

  private addFeedFromTask(task: SpaceTask, completerId: string, completerName: string): void {
    if (task.checkInPhotoUrl.length === 0) {
      return;
    }
    const phrase: string = task.description.length > 0 ? task.description : '完成打卡';
    const recipeId: string = task.relatedRecipeId.length > 0 ? task.relatedRecipeId : task.id;
    this.addFeedComplete(recipeId, task.title, phrase, task.checkInPhotoUrl, completerId, completerName);
  }

  publishCookComplete(recipeId: string, recipeTitle: string, phrase: string, photoUrl: string,
    userId: string, userName: string): void {
    this.ensureLoaded();
    let task: SpaceTask | undefined = this.findCookingTask(recipeId, userId,
      [SpaceTaskStatus.PENDING_CHECKIN]);
    if (task === undefined) {
      task = this.findCookingTask(recipeId, userId, [SpaceTaskStatus.DOING]);
    }
    this.addFeedComplete(recipeId, recipeTitle, phrase, photoUrl, userId, userName);
    if (task !== undefined) {
      task.type = SpaceTaskType.RECIPE_DONE;
      task.title = `完成了：${recipeTitle}`;
      task.description = phrase;
      task.checkInPhotoUrl = photoUrl;
      task.status = SpaceTaskStatus.DONE;
      task.assigneeId = userId;
      task.updatedAt = Date.now();
      task.isRead = false;
    } else {
      this.createRecipeDoneTask(recipeId, recipeTitle, userId, photoUrl);
    }
    this.incrementCookCompletedCount();
    this.bump();
  }

  createForwardTask(recipeId: string, recipeTitle: string, phrase: string, creatorId: string,
    priority: number, creatorName: string = ''): SpaceTask {
    const task: SpaceTask = this.createTask(SpaceTaskType.RECIPE_FORWARD, `想做：${recipeTitle}`, creatorId,
      phrase, recipeId, priority);
    if (creatorName.length > 0) {
      const detail: string = phrase.length > 0 ? phrase : '想做了这道菜';
      this.addFeedAction(creatorId, creatorName, recipeTitle, detail, recipeId);
      this.bump();
    }
    return task;
  }

  publishTask(type: SpaceTaskType, title: string, creatorId: string, creatorName: string,
    description: string, relatedRecipeId: string, priority: number): SpaceTask {
    const task: SpaceTask = this.createTask(type, title, creatorId, description, relatedRecipeId, priority);
    if (creatorName.length > 0) {
      this.addFeedAction(creatorId, creatorName, title, '发布了待办', task.id);
      this.bump();
    }
    return task;
  }

  getTasks(): SpaceTask[] {
    this.ensureLoaded();
    return [...this.store.tasks].sort((a: SpaceTask, b: SpaceTask) => this.compareTasks(a, b));
  }

  getVisibleActiveTasks(userId: string): SpaceTask[] {
    this.ensureLoaded();
    return this.store.tasks
      .filter((t: SpaceTask) => this.isVisibleToUser(t, userId))
      .sort((a: SpaceTask, b: SpaceTask) => this.compareTasks(a, b));
  }

  /** 一级/二级/三级槽位：仅展示待接取 / 进行中 */
  getWorkingTasks(userId: string): SpaceTask[] {
    this.ensureLoaded();
    return this.store.tasks
      .filter((t: SpaceTask) =>
        t.status === SpaceTaskStatus.OPEN || t.status === SpaceTaskStatus.DOING)
      .sort((a: SpaceTask, b: SpaceTask) => this.compareTasks(a, b));
  }

  /** 待夸赞：完成方已提交，另一方需在任务 Tab 处理 */
  getPendingPraiseTasks(userId: string): SpaceTask[] {
    this.ensureLoaded();
    return this.store.tasks
      .filter((t: SpaceTask) =>
        t.status === SpaceTaskStatus.DONE && t.assigneeId !== userId)
      .sort((a: SpaceTask, b: SpaceTask) => b.updatedAt - a.updatedAt);
  }

  getDoingTasks(_userId: string): SpaceTask[] {
    this.ensureLoaded();
    return this.store.tasks
      .filter((t: SpaceTask) => t.status === SpaceTaskStatus.DOING)
      .sort((a: SpaceTask, b: SpaceTask) => b.updatedAt - a.updatedAt);
  }

  getTasksTabCount(userId: string): number {
    return this.getDoingTasks(userId).length +
      this.getPendingCheckInTasks(userId).length +
      this.getPendingPraiseTasks(userId).length;
  }

  getActiveTasks(): SpaceTask[] {
    return this.getTasks().filter((t: SpaceTask) =>
      t.status !== SpaceTaskStatus.PRAISED && t.status !== SpaceTaskStatus.CANCELLED);
  }

  getSlotTask(userId: string, priority: number): SpaceTask | undefined {
    return this.getWorkingTasks(userId).find((t: SpaceTask) => t.priority === priority);
  }

  getWorkingTasksByPriority(userId: string, priority: number): SpaceTask[] {
    return this.getWorkingTasks(userId).filter((t: SpaceTask) => t.priority === priority);
  }

  getTaskById(id: string): SpaceTask | undefined {
    return this.store.tasks.find((t: SpaceTask) => t.id === id);
  }

  createTask(type: SpaceTaskType, title: string, creatorId: string, description: string,
    relatedRecipeId: string, priority: number): SpaceTask {
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
      priority: priority >= 1 && priority <= 3 ? priority : 2,
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

  createRecipeDoneTask(recipeId: string, title: string, userId: string,
    photoUrl: string = ''): SpaceTask {
    const task: SpaceTask = this.createTask(SpaceTaskType.RECIPE_DONE, `完成了：${title}`, userId, '',
      recipeId, 2);
    task.assigneeId = userId;
    task.status = SpaceTaskStatus.DONE;
    task.checkInPhotoUrl = photoUrl;
    task.isRead = false;
    this.bump();
    return task;
  }

  acceptTask(taskId: string, userId: string, userName: string = ''): void {
    this.ensureLoaded();
    const task: SpaceTask | undefined = this.getTaskById(taskId);
    if (task === undefined || task.status !== SpaceTaskStatus.OPEN) {
      return;
    }
    if (task.assigneeId.length > 0) {
      return;
    }
    task.assigneeId = userId;
    task.status = SpaceTaskStatus.DOING;
    task.updatedAt = Date.now();
    task.isRead = false;
    if (userName.length > 0) {
      this.addFeedAction(userId, userName, task.title, '接取了任务', task.id);
    }
    this.bump();
  }

  private revertCookingToForward(task: SpaceTask): void {
    if (task.type !== SpaceTaskType.RECIPE_COOKING) {
      return;
    }
    const recipeTitle: string = task.title.replace('制作中：', '').replace('待打卡：', '');
    task.type = SpaceTaskType.RECIPE_FORWARD;
    task.title = `想做：${recipeTitle}`;
  }

  abandonTask(taskId: string, userId: string, userName: string = ''): void {
    this.ensureLoaded();
    const task: SpaceTask | undefined = this.getTaskById(taskId);
    if (task === undefined || task.status !== SpaceTaskStatus.DOING) {
      return;
    }
    if (task.assigneeId !== userId) {
      return;
    }
    if (userName.length > 0) {
      this.addFeedAction(userId, userName, task.title, '取消了任务', task.id);
    }
    this.revertCookingToForward(task);
    task.assigneeId = '';
    task.status = SpaceTaskStatus.OPEN;
    task.updatedAt = Date.now();
    task.isRead = false;
    this.bump();
  }

  markTaskPendingCheckIn(taskId: string, userId: string, userName: string = ''): boolean {
    this.ensureLoaded();
    const task: SpaceTask | undefined = this.getTaskById(taskId);
    if (task === undefined || task.status !== SpaceTaskStatus.DOING) {
      return false;
    }
    if (task.assigneeId !== userId) {
      return false;
    }
    task.status = SpaceTaskStatus.PENDING_CHECKIN;
    task.updatedAt = Date.now();
    task.isRead = false;
    if (userName.length > 0) {
      this.addFeedAction(userId, userName, task.title, '标记已完成，待上传打卡', task.id);
    }
    this.bump();
    return true;
  }

  publishTaskCheckIn(taskId: string, photoUrl: string, userId: string, userName: string,
    phrase: string = '完成打卡'): void {
    this.ensureLoaded();
    const task: SpaceTask | undefined = this.getTaskById(taskId);
    if (task === undefined || task.status !== SpaceTaskStatus.PENDING_CHECKIN) {
      return;
    }
    if (task.assigneeId !== userId) {
      return;
    }
    task.checkInPhotoUrl = photoUrl;
    task.description = phrase;
    const relatedId: string = task.relatedRecipeId.length > 0 ? task.relatedRecipeId : task.id;
    this.addFeedComplete(relatedId, task.title, phrase, photoUrl, userId, userName);
    task.status = SpaceTaskStatus.DONE;
    task.updatedAt = Date.now();
    task.isRead = false;
    this.bump();
  }

  completeTask(taskId: string, userId: string, userName: string = ''): void {
    this.markTaskPendingCheckIn(taskId, userId, userName);
  }

  praiseTask(taskId: string, userId: string, phrase: string, userName: string = ''): void {
    this.ensureLoaded();
    const task: SpaceTask | undefined = this.getTaskById(taskId);
    if (task === undefined || task.status !== SpaceTaskStatus.DONE) {
      return;
    }
    if (task.assigneeId === userId) {
      return;
    }
    task.praiseText = phrase;
    task.praisedBy = userId;
    task.status = SpaceTaskStatus.PRAISED;
    task.updatedAt = Date.now();
    task.isRead = false;
    if (userName.length > 0) {
      this.addFeedAction(userId, userName, task.title, `夸赞：${phrase}`, task.id);
    }
    this.bump();
  }

  cancelTask(taskId: string, userId: string, userName: string = ''): void {
    this.ensureLoaded();
    const task: SpaceTask | undefined = this.getTaskById(taskId);
    if (task === undefined) {
      return;
    }
    if (task.status === SpaceTaskStatus.PRAISED || task.status === SpaceTaskStatus.CANCELLED) {
      return;
    }
    if (task.status !== SpaceTaskStatus.OPEN) {
      return;
    }
    if (userName.length > 0) {
      this.addFeedAction(userId, userName, task.title, '取消了待办', task.id);
    }
    task.status = SpaceTaskStatus.CANCELLED;
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
      if (t.status === SpaceTaskStatus.CANCELLED) {
        return;
      }
      if (!t.isRead && t.status === SpaceTaskStatus.DONE && t.assigneeId !== userId) {
        count += 1;
      }
      if (!t.isRead && t.status === SpaceTaskStatus.PRAISED && t.assigneeId === userId) {
        count += 1;
      }
      if (!t.isRead && t.status === SpaceTaskStatus.OPEN) {
        count += 1;
      }
      if (!t.isRead && t.status === SpaceTaskStatus.DOING && t.assigneeId !== userId) {
        count += 1;
      }
    });
    return count;
  }
}
