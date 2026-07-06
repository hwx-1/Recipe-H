/**
 * TasksPage - 任务(Tab)
 *
 * 作用：集中展示两类待办——
 *   1) 进行中的烹饪会话(带进度条，可直接“做完了/放弃”)；
 *   2) 情侣空间的待办任务(SpaceTask)。
 *   两者都为空时展示引导文案：“目前无待办事项，可以想想做什么或者买什么啦”。
 * 复用：MainPage 的“任务”Tab 内容。
 */
import { promptAction } from '@kit.ArkUI';
import { EmptyState } from '../components/common/EmptyState';
import { CookingSession } from '../model/CookingSession';
import { CookingSessionManager } from '../service/CookingSessionManager';
import { SpaceRepository, KEY_SPACE_BOUND, SPACE_VERSION } from '../repository/SpaceRepository';
import { SpaceTask } from '../model/SpaceTask';
import { SpaceTaskCard } from '../components/space/SpaceTaskCard';
import { RouteName } from '../common/Constants';
import { KEY_USER_UNION_ID } from '../service/AccountService';
import { SoundService } from '../service/SoundService';

@Component
export struct TasksPage {
  pathStack: NavPathStack = new NavPathStack();
  @StorageLink('activeCookingCount') private cookingCount: number = 0;
  @StorageLink(SPACE_VERSION) private spaceVersion: number = 0;
  @StorageLink(KEY_SPACE_BOUND) private bound: boolean = false;
  @StorageLink(KEY_USER_UNION_ID) private userId: string = '';
  @State private sessions: CookingSession[] = [];
  @State private spaceTasks: SpaceTask[] = [];
  @State private now: number = Date.now();
  private timerId: number = -1;

  aboutToAppear(): void {
    this.refresh();
    this.timerId = setInterval(() => {
      this.now = Date.now();
      this.refresh();
    }, 1000);
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private refresh(): void {
    this.sessions = CookingSessionManager.getInstance().getActive();
    if (this.bound) {
      this.spaceTasks = SpaceRepository.getInstance().getActiveTasks();
    } else {
      this.spaceTasks = [];
    }
  }

  private hasAnyTodo(): boolean {
    return this.sessions.length > 0 || this.spaceTasks.length > 0;
  }

  /**
   * 计算进度百分比(0-100)，最高 100。
   */
  private progressOf(s: CookingSession): number {
    const total: number = s.expectedEndTime - s.startTime;
    if (total <= 0) {
      return 100;
    }
    const ratio: number = (this.now - s.startTime) / total * 100;
    return Math.min(Math.max(ratio, 0), 100);
  }

  private remainText(s: CookingSession): string {
    const remainMs: number = s.expectedEndTime - this.now;
    if (remainMs <= 0) {
      return '已超时，做完了吗？';
    }
    const min: number = Math.ceil(remainMs / 60000);
    return `预计还需 ${min} 分钟`;
  }

  @Builder
  CookingItem(s: CookingSession) {
    Column({ space: 8 }) {
      Row() {
        Text(`🍳 ${s.recipeTitle}`)
          .fontSize($r('app.float.font_body'))
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Text(this.remainText(s))
          .fontSize($r('app.float.font_caption'))
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')

      Progress({ value: this.progressOf(s), total: 100, type: ProgressType.Linear })
        .color($r('app.color.brand'))
        .width('100%')

      Row({ space: 12 }) {
        Button('做完了')
          .height(36)
          .fontSize($r('app.float.font_caption'))
          .fontColor($r('app.color.text_on_brand'))
          .backgroundColor($r('app.color.brand'))
          .borderRadius(18)
          .onClick(() => {
            CookingSessionManager.getInstance().completeByRecipe(s.recipeId);
            if (this.bound && this.userId.length > 0) {
              SpaceRepository.getInstance().createRecipeDoneTask(s.recipeId, s.recipeTitle, this.userId);
            }
            this.refresh();
            SoundService.feedback();
            promptAction.showToast({ message: '完成打卡！', duration: 1200 });
          })
        Button('放弃')
          .height(36)
          .fontSize($r('app.float.font_caption'))
          .fontColor($r('app.color.text_secondary'))
          .backgroundColor($r('app.color.page_bg'))
          .borderRadius(18)
          .onClick(() => {
            CookingSessionManager.getInstance().abandonByRecipe(s.recipeId);
            this.refresh();
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius($r('app.float.radius_card'))
  }

  @Builder
  SectionHeader(text: string) {
    Text(text)
      .fontSize($r('app.float.font_subtitle'))
      .fontWeight(FontWeight.Medium)
      .fontColor($r('app.color.text_primary'))
      .width('100%')
      .margin({ top: 8 })
  }

  build() {
    Column() {
      Text($r('app.string.tab_tasks'))
        .fontSize($r('app.float.font_title'))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .padding({ left: 16, top: 12, bottom: 12 })

      if (!this.hasAnyTodo()) {
        Column() {
          EmptyState({ emoji: '🗒️', message: '目前无待办事项，可以想想做什么或者买什么啦' })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 12 }) {
            if (this.sessions.length > 0) {
              this.SectionHeader('进行中的烹饪')
              ForEach(this.sessions, (s: CookingSession) => {
                this.CookingItem(s)
              }, (s: CookingSession) => s.id)
            }

            if (this.spaceTasks.length > 0) {
              this.SectionHeader('空间待办')
              ForEach(this.spaceTasks, (task: SpaceTask) => {
                SpaceTaskCard({
                  task: task,
                  showUnread: true,
                  onCardClick: (taskId: string) => {
                    this.pathStack.pushPath({ name: RouteName.TASK_DETAIL, param: taskId });
                  }
                })
              }, (task: SpaceTask) => `${task.id}_${this.spaceVersion}`)
            }
          }
          .padding({ left: 16, right: 16, bottom: 24 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}
