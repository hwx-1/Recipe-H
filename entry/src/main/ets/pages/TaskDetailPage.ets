/**
 * TaskDetailPage - 空间任务详情页
 *
 * 作用：展示单条 SpaceTask，支持接取、完成打卡(含本地照片)、夸赞流程。
 */
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { PraisePicker } from '../components/space/PraisePicker';
import { SpaceTask, SpaceTaskStatus, SpaceTaskType } from '../model/SpaceTask';
import { SpaceRepository, SPACE_VERSION } from '../repository/SpaceRepository';
import { KEY_USER_UNION_ID } from '../service/AccountService';
import { LocalPhotoService } from '../service/LocalPhotoService';
import { SoundService } from '../service/SoundService';
import { rippleTransition } from '../common/transition/WaterRippleTransition';

@Component
export struct TaskDetailPage {
  @Prop taskId: string = '';
  pathStack: NavPathStack = new NavPathStack();
  @StorageLink(KEY_USER_UNION_ID) private userId: string = '';
  @StorageLink(SPACE_VERSION) private spaceVersion: number = 0;
  @State private task: SpaceTask | undefined = undefined;
  @State private pickingPhoto: boolean = false;

  aboutToAppear(): void {
    this.loadTask();
  }

  private loadTask(): void {
    const t: SpaceTask | undefined = SpaceRepository.getInstance().getTaskById(this.taskId);
    this.task = t;
    if (t !== undefined) {
      SpaceRepository.getInstance().markTaskRead(this.taskId);
    }
  }

  private typeLabel(): string {
    if (this.task === undefined) {
      return '';
    }
    if (this.task.type === SpaceTaskType.RECIPE_DONE) {
      return '🍳 做完的菜';
    }
    if (this.task.type === SpaceTaskType.ERRAND) {
      return '🛒 跑腿';
    }
    if (this.task.type === SpaceTaskType.CRAVING) {
      return '😋 想吃';
    }
    if (this.task.type === SpaceTaskType.DAILY_PACT) {
      return '🤝 每日约定';
    }
    return '📝 自定义';
  }

  private statusLabel(): string {
    if (this.task === undefined) {
      return '';
    }
    if (this.task.status === SpaceTaskStatus.OPEN) {
      return '待接取';
    }
    if (this.task.status === SpaceTaskStatus.DOING) {
      return '进行中';
    }
    if (this.task.status === SpaceTaskStatus.DONE) {
      return '待夸赞';
    }
    return '已完成';
  }

  private canAccept(): boolean {
    if (this.task === undefined || this.userId.length === 0) {
      return false;
    }
    return this.task.status === SpaceTaskStatus.OPEN && this.task.creatorId !== this.userId;
  }

  private canComplete(): boolean {
    if (this.task === undefined || this.userId.length === 0) {
      return false;
    }
    if (this.task.status !== SpaceTaskStatus.DOING) {
      return false;
    }
    if (this.task.assigneeId.length > 0) {
      return this.task.assigneeId === this.userId;
    }
    return this.task.creatorId !== this.userId;
  }

  private canAddPhoto(): boolean {
    if (this.task === undefined) {
      return false;
    }
    return this.task.status === SpaceTaskStatus.DOING &&
      (this.task.type === SpaceTaskType.ERRAND ||
        this.task.type === SpaceTaskType.DAILY_PACT ||
        this.task.type === SpaceTaskType.CUSTOM);
  }

  private praisedPersonId(): string {
    if (this.task === undefined) {
      return '';
    }
    if (this.task.assigneeId.length > 0) {
      return this.task.assigneeId;
    }
    return this.task.creatorId;
  }

  private canPraise(): boolean {
    if (this.task === undefined || this.userId.length === 0) {
      return false;
    }
    return this.task.status === SpaceTaskStatus.DONE && this.userId !== this.praisedPersonId();
  }

  private async pickPhoto(): Promise<void> {
    if (this.pickingPhoto) {
      return;
    }
    this.pickingPhoto = true;
    try {
      const context: common.Context = getContext(this) as common.Context;
      const url: string = await LocalPhotoService.pickCheckInPhoto(context, this.taskId);
      if (url.length > 0) {
        SpaceRepository.getInstance().attachCheckInPhoto(this.taskId, url);
        this.loadTask();
        promptAction.showToast({ message: '打卡照片已添加', duration: 1200 });
      }
    } catch (_err) {
      promptAction.showToast({ message: '选图失败，请检查相册权限', duration: 2000 });
    } finally {
      this.pickingPhoto = false;
    }
  }

  build() {
    NavDestination() {
      if (this.task === undefined) {
        Column() {
          Text('任务不存在或已删除')
            .fontSize($r('app.float.font_body'))
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 16 }) {
            Text(this.typeLabel())
              .fontSize($r('app.float.font_caption'))
              .fontColor($r('app.color.text_secondary'))
              .width('100%')

            Text(this.task.title)
              .fontSize($r('app.float.font_title'))
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .width('100%')

            Text(this.statusLabel())
              .fontSize($r('app.float.font_caption'))
              .fontColor($r('app.color.brand'))
              .width('100%')

            if (this.task.description.length > 0) {
              Text(this.task.description)
                .fontSize($r('app.float.font_body'))
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
            }

            if (this.task.checkInPhotoUrl.length > 0) {
              Image(this.task.checkInPhotoUrl)
                .width('100%')
                .height(200)
                .borderRadius(12)
                .objectFit(ImageFit.Cover)
                .backgroundColor($r('app.color.brand_light'))
            }

            if (this.canAddPhoto()) {
              Button(this.pickingPhoto ? '选图中...' : '添加打卡照片')
                .width('100%')
                .height(42)
                .fontColor($r('app.color.brand'))
                .backgroundColor($r('app.color.brand_light'))
                .borderRadius(21)
                .enabled(!this.pickingPhoto)
                .onClick(() => {
                  this.pickPhoto();
                })
            }

            if (this.task.status === SpaceTaskStatus.PRAISED && this.task.praiseText.length > 0) {
              Column({ space: 8 }) {
                Text('TA 说')
                  .fontSize($r('app.float.font_caption'))
                  .fontColor($r('app.color.text_secondary'))
                Text(this.task.praiseText)
                  .fontSize($r('app.float.font_body'))
                  .fontColor($r('app.color.brand'))
              }
              .width('100%')
              .padding(16)
              .backgroundColor($r('app.color.brand_light'))
              .borderRadius(12)
            }

            if (this.canAccept()) {
              Button('接取任务')
                .width('100%')
                .height(46)
                .fontColor($r('app.color.text_on_brand'))
                .backgroundColor($r('app.color.brand'))
                .borderRadius(23)
                .onClick(() => {
                  SpaceRepository.getInstance().acceptTask(this.taskId, this.userId);
                  this.loadTask();
                  SoundService.feedback();
                  promptAction.showToast({ message: '已接取', duration: 1200 });
                })
            }

            if (this.canComplete()) {
              Button('标记完成')
                .width('100%')
                .height(46)
                .fontColor($r('app.color.text_on_brand'))
                .backgroundColor($r('app.color.brand'))
                .borderRadius(23)
                .onClick(() => {
                  SpaceRepository.getInstance().completeTask(this.taskId, this.userId);
                  this.loadTask();
                  SoundService.feedback();
                  promptAction.showToast({ message: '已完成，等 TA 夸夸你', duration: 1500 });
                })
            }

            if (this.canPraise()) {
              PraisePicker({
                onSelect: (phrase: string) => {
                  SpaceRepository.getInstance().praiseTask(this.taskId, this.userId, phrase);
                  this.loadTask();
                  SoundService.feedback();
                  promptAction.showToast({ message: '已发送夸赞', duration: 1200 });
                }
              })
            }
          }
          .padding(16)
        }
        .width('100%')
        .height('100%')
      }
    }
    .title('任务详情')
    .backgroundColor($r('app.color.page_bg'))
    .onShown(() => {
      this.loadTask();
    })
    .transition(rippleTransition())
  }
}
