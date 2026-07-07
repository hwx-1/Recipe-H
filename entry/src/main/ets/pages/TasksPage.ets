/**
 * TasksPage - 任务(Tab)：进行中 + 待打卡 + 待夸赞
 */
import { EmptyState } from '../components/common/EmptyState';
import { SpaceTaskCard } from '../components/space/SpaceTaskCard';
import { SpaceRepository, SPACE_VERSION } from '../repository/SpaceRepository';
import { SpaceTask, SpaceTaskType } from '../model/SpaceTask';
import { RouteName } from '../common/Constants';
import { LocalUserService } from '../service/LocalUserService';

@Component
export struct TasksPage {
  pathStack: NavPathStack = new NavPathStack();
  private readonly userId: string = LocalUserService.getSelfId();
  @StorageLink(SPACE_VERSION) @Watch('onSpaceChanged') private spaceVersion: number = 0;
  @State private doingTasks: SpaceTask[] = [];
  @State private checkInTasks: SpaceTask[] = [];
  @State private praiseTasks: SpaceTask[] = [];

  aboutToAppear(): void {
    SpaceRepository.getInstance().ensureLocalCoupleSpace();
    this.refresh();
  }

  private onSpaceChanged(): void {
    this.refresh();
  }

  private refresh(): void {
    const repo: SpaceRepository = SpaceRepository.getInstance();
    this.doingTasks = repo.getDoingTasks(this.userId);
    this.checkInTasks = repo.getPendingCheckInTasks(this.userId);
    this.praiseTasks = repo.getPendingPraiseTasks(this.userId);
  }

  private hasAnyContent(): boolean {
    return this.doingTasks.length > 0 || this.checkInTasks.length > 0 || this.praiseTasks.length > 0;
  }

  private openTaskDetail(taskId: string): void {
    this.pathStack.pushPath({ name: RouteName.TASK_DETAIL, param: taskId });
  }

  private openCheckIn(task: SpaceTask): void {
    if (task.type === SpaceTaskType.RECIPE_COOKING && task.relatedRecipeId.length > 0) {
      this.pathStack.pushPath({ name: RouteName.COOK_COMPLETE, param: task.relatedRecipeId });
    } else {
      this.openTaskDetail(task.id);
    }
  }

  @Builder
  CheckInItem(task: SpaceTask) {
    Column({ space: 8 }) {
      Row() {
        Text(`📷 ${task.title}`)
          .fontSize($r('app.float.font_body'))
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Text('待打卡')
          .fontSize($r('app.float.font_caption'))
          .fontColor($r('app.color.brand'))
      }
      .width('100%')

      Button('上传打卡照片')
        .width('100%')
        .height(40)
        .fontSize($r('app.float.font_caption'))
        .fontColor($r('app.color.text_on_brand'))
        .backgroundColor($r('app.color.brand'))
        .borderRadius(20)
        .onClick(() => {
          this.openCheckIn(task);
        })
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

      if (!this.hasAnyContent()) {
        Column() {
          EmptyState({ emoji: '🗒️', message: '暂无进行中的任务' })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 12 }) {
            if (this.doingTasks.length > 0) {
              this.SectionHeader('进行中')
              ForEach(this.doingTasks, (task: SpaceTask) => {
                SpaceTaskCard({
                  task: task,
                  viewerId: this.userId,
                  showUnread: true,
                  onCardClick: (taskId: string) => {
                    this.openTaskDetail(taskId);
                  }
                })
              }, (task: SpaceTask) => `${task.id}_${this.spaceVersion}`)
            }

            if (this.checkInTasks.length > 0) {
              this.SectionHeader('待打卡')
              ForEach(this.checkInTasks, (task: SpaceTask) => {
                this.CheckInItem(task)
              }, (task: SpaceTask) => `${task.id}_${this.spaceVersion}`)
            }

            if (this.praiseTasks.length > 0) {
              this.SectionHeader('待夸赞')
              ForEach(this.praiseTasks, (task: SpaceTask) => {
                SpaceTaskCard({
                  task: task,
                  viewerId: this.userId,
                  showUnread: true,
                  onCardClick: (taskId: string) => {
                    this.openTaskDetail(taskId);
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
    .onVisibleAreaChange([0.0, 1.0], (isExpanding: boolean, _currentRatio: number) => {
      if (isExpanding) {
        this.refresh();
      }
    })
  }
}
