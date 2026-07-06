/**
 * CookingSessionManager - 烹饪会话管理器
 *
 * 作用：管理并行的烹饪会话，负责计时与超时提醒；会话持久化到 Preferences，重启后恢复。
 */
import { promptAction } from '@kit.ArkUI';
import { CookingSession, CookingStatus } from '../model/CookingSession';
import { Recipe } from '../model/Recipe';
import { AppConst, PrefKey } from '../common/Constants';
import { PrefsUtil } from '../common/PrefsUtil';

export const ACTIVE_COOKING_COUNT: string = 'activeCookingCount';

export class CookingSessionManager {
  private static instance: CookingSessionManager | undefined = undefined;
  private sessions: Map<string, CookingSession> = new Map<string, CookingSession>();
  private timers: Map<string, number> = new Map<string, number>();
  private restored: boolean = false;

  static getInstance(): CookingSessionManager {
    if (CookingSessionManager.instance === undefined) {
      CookingSessionManager.instance = new CookingSessionManager();
      AppStorage.setOrCreate(ACTIVE_COOKING_COUNT, 0);
    }
    return CookingSessionManager.instance;
  }

  /**
   * 从 Preferences 恢复进行中的会话（EntryAbility 启动时调用）。
   */
  restoreSessions(): void {
    if (this.restored) {
      return;
    }
    this.restored = true;
    const raw: string = PrefsUtil.getString(PrefKey.COOKING_SESSIONS, '[]');
    if (raw.length === 0) {
      return;
    }
    const list: CookingSession[] = JSON.parse(raw) as CookingSession[];
    list.forEach((s: CookingSession) => {
      if (s.status === CookingStatus.ACTIVE) {
        this.sessions.set(s.id, s);
        this.scheduleReminder(s);
      }
    });
    this.syncCount();
  }

  private persistSessions(): void {
    const list: CookingSession[] = Array.from(this.sessions.values());
    PrefsUtil.setString(PrefKey.COOKING_SESSIONS, JSON.stringify(list));
  }

  private syncCount(): void {
    AppStorage.setOrCreate(ACTIVE_COOKING_COUNT, this.sessions.size);
  }

  private computeExpectedEnd(startTime: number, timeMinutes: number): number {
    const byRecipe: number = timeMinutes * AppConst.COOK_TIME_FACTOR;
    const minutes: number = Math.max(byRecipe, AppConst.COOK_MIN_MINUTES);
    return startTime + minutes * 60 * 1000;
  }

  isCooking(recipeId: string): boolean {
    let found: boolean = false;
    this.sessions.forEach((s: CookingSession) => {
      if (s.recipeId === recipeId && s.status === CookingStatus.ACTIVE) {
        found = true;
      }
    });
    return found;
  }

  start(recipe: Recipe): string {
    const now: number = Date.now();
    const id: string = `cs_${recipe.id}_${now}`;
    const session: CookingSession = {
      id: id,
      recipeId: recipe.id,
      recipeTitle: recipe.title,
      startTime: now,
      expectedEndTime: this.computeExpectedEnd(now, recipe.timeMinutes),
      status: CookingStatus.ACTIVE
    };
    this.sessions.set(id, session);
    this.scheduleReminder(session);
    this.syncCount();
    this.persistSessions();
    return id;
  }

  private scheduleReminder(session: CookingSession): void {
    const delay: number = session.expectedEndTime - Date.now();
    if (delay <= 0) {
      return;
    }
    const timerId: number = setTimeout(() => {
      if (this.sessions.has(session.id) && PrefsUtil.getBoolean(PrefKey.COOK_REMINDER_ENABLED, true)) {
        promptAction.showToast({
          message: `《${session.recipeTitle}》做好了吗？记得点“做完了”打卡`,
          duration: 2500
        });
      }
      this.timers.delete(session.id);
    }, delay);
    this.timers.set(session.id, timerId);
  }

  private clearTimer(id: string): void {
    const timerId: number | undefined = this.timers.get(id);
    if (timerId !== undefined) {
      clearTimeout(timerId);
      this.timers.delete(id);
    }
  }

  completeByRecipe(recipeId: string): CookingSession | undefined {
    let target: CookingSession | undefined = undefined;
    this.sessions.forEach((s: CookingSession) => {
      if (s.recipeId === recipeId && s.status === CookingStatus.ACTIVE) {
        target = s;
      }
    });
    if (target !== undefined) {
      const session: CookingSession = target;
      this.clearTimer(session.id);
      this.sessions.delete(session.id);
      this.syncCount();
      this.persistSessions();
      this.incrementCompletedCount();
    }
    return target;
  }

  abandonByRecipe(recipeId: string): void {
    let targetId: string = '';
    this.sessions.forEach((s: CookingSession) => {
      if (s.recipeId === recipeId && s.status === CookingStatus.ACTIVE) {
        targetId = s.id;
      }
    });
    if (targetId.length > 0) {
      this.clearTimer(targetId);
      this.sessions.delete(targetId);
      this.syncCount();
      this.persistSessions();
    }
  }

  getActive(): CookingSession[] {
    return Array.from(this.sessions.values());
  }

  getCompletedCount(): number {
    return PrefsUtil.getNumber(PrefKey.COOKING_COMPLETED_COUNT, 0);
  }

  private incrementCompletedCount(): void {
    const count: number = this.getCompletedCount() + 1;
    PrefsUtil.setNumber(PrefKey.COOKING_COMPLETED_COUNT, count);
  }
}
