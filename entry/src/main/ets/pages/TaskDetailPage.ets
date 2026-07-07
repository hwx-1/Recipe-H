/**
 * TaskDetailPage - 空间任务详情页
 */
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { PraisePicker } from '../components/space/PraisePicker';
import { SpaceTask, SpaceTaskStatus, SpaceTaskType } from '../model/SpaceTask';
import { SpaceRepository, SPACE_VERSION } from '../repository/SpaceRepository';
import { LocalUserService } from '../service/LocalUserService';
import { LocalPhotoService, PhotoPickSource } from '../service/LocalPhotoService';
import { SoundService } from '../service/SoundService';
import { rippleTransition } from '../common/transition/WaterRippleTransition';
import { RouteName } from '../common/Constants';

@Component
export struct TaskDetailPage {
  @Prop taskId: string = '';
  pathStack: NavPathStack = new NavPathStack();
  private readonly userId: string = LocalUserService.getSelfId();
  private readonly userName: string = LocalUserService.getSelfName();
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

  private priorityLabel(): string {
    if (this.task === undefined) {
      return '';
    }
    if (this.task.priority === 1) {
      return '一级优先级';
    }
    if (this.task.priority === 2) {
      return '二级优先级';
    }
    return '三级优先级';
  }

  private typeLabel(): string {
    if (this.task === undefined) {
      return '';
    }
    if (this.task.type === SpaceTaskType.RECIPE_DONE || this.task.type === SpaceTaskType.RECIPE_COOKING) {
      return '🍳 做菜';
    }
    if (this.task.type === SpaceTaskType.RECIPE_FORWARD) {
      return '💡 想做的菜';
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
    return SpaceRepository.getInstance().getTaskStatusLabel(this.task, this.userId);
  }

  private canAccept(): boolean {
    if (this.task === undefined) {
      return false;
    }
    return this.task.status === SpaceTaskStatus.OPEN && this.task.assigneeId.length === 0;
  }

  private canDismissOpenTask(): boolean {
    if (this.task === undefined) {
      return false;
    }
    return this.task.status === SpaceTaskStatus.OPEN;
  }

  private dismissOpenTask(): void {
    SpaceRepository.getInstance().cancelTask(this.taskId, this.userId, this.userName);
    promptAction.showToast({ message: '已取消该任务', duration: 1200 });
    this.pathStack.pop();
  }

  private isRecipeCookingTask(): boolean {
    return this.task !== undefined && this.task.type === SpaceTaskType.RECIPE_COOKING;
  }

  private canCancelTask(): boolean {
    if (this.task === undefined) {
      return false;
    }
    return this.task.status === SpaceTaskStatus.DOING && this.task.assigneeId === this.userId;
  }

  private canMarkComplete(): boolean {
    if (this.task === undefined || this.isRecipeCookingTask()) {
      return false;
    }
    return this.task.status === SpaceTaskStatus.DOING && this.task.assigneeId === this.userId;
  }

  private canFinishCooking(): boolean {
    if (this.task === undefined || !this.isRecipeCookingTask()) {
      return false;
    }
    return this.task.status === SpaceTaskStatus.DOING && this.task.assigneeId === this.userId;
  }

  private canUploadCheckIn(): boolean {
    if (this.task === undefined || this.isRecipeCookingTask()) {
      return false;
    }
    return this.task.status === SpaceTaskStatus.PENDING_CHECKIN && this.task.assigneeId === this.userId;
  }

  private canCheckInCooking(): boolean {
    if (this.task === undefined || !this.isRecipeCookingTask()) {
      return false;
    }
    return this.task.status === SpaceTaskStatus.PENDING_CHECKIN && this.task.assigneeId === this.userId;
  }

  private canPublishCheckIn(): boolean {
    if (this.task === undefined) {
      return false;
    }
    return this.canUploadCheckIn() && this.task.checkInPhotoUrl.length > 0;
  }

  private canPraise(): boolean {
    if (this.task === undefined) {
      return false;
    }
    return this.task.status === SpaceTaskStatus.DONE && this.task.assigneeId !== this.userId;
  }

  private cancelCurrentTask(): void {
    if (this.task === undefined) {
      return;
    }
    if (this.isRecipeCookingTask() && this.task.relatedRecipeId.length > 0) {
      SpaceRepository.getInstance()
        .cancelCookingTask(this.task.relatedRecipeId, this.userId, this.userName);
    } else {
      SpaceRepository.getInstance().abandonTask(this.taskId, this.userId, this.userName);
    }
    this.loadTask();
    promptAction.showToast({ message: '已取消，任务恢复为待接取', duration: 1500 });
  }

  private async pickPhoto(source: PhotoPickSource): Promise<void> {
    if (this.pickingPhoto) {
      return;
    }
    this.pickingPhoto = true;
    try {
      const context: common.Context = getContext(this) as common.Context;
      const url: string = await LocalPhotoService.pickCheckInPhoto(context, this.taskId, source);
      if (url.length > 0) {
        SpaceRepository.getInstance().attachCheckInPhoto(this.taskId, url);
        this.loadTask();
        promptAction.showToast({ message: '打卡照片已添加', duration: 1200 });
      }
    } catch (_err) {
      const hint: string = source === PhotoPickSource.CAMERA ?
        '拍照失败，请检查相机权限' : '选图失败，请检查相册权限';
      promptAction.showToast({ message: hint, duration: 2000 });
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

            Text(`${this.priorityLabel()} · ${this.statusLabel()}`)
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

            if (this.canUploadCheckIn()) {
              Row({ space: 12 }) {
                Button(this.pickingPhoto ? '处理中...' : '拍照')
                  .layoutWeight(1)
                  .height(42)
                  .fontColor($r('app.color.text_on_brand'))
                  .backgroundColor($r('app.color.brand'))
                  .borderRadius(21)
                  .enabled(!this.pickingPhoto)
                  .onClick(() => {
                    this.pickPhoto(PhotoPickSource.CAMERA);
                  })
                Button(this.pickingPhoto ? '处理中...' : '从相册选择')
                  .layoutWeight(1)
                  .height(42)
                  .fontColor($r('app.color.brand'))
                  .backgroundColor($r('app.color.brand_light'))
                  .borderRadius(21)
                  .enabled(!this.pickingPhoto)
                  .onClick(() => {
                    this.pickPhoto(PhotoPickSource.ALBUM);
                  })
              }
              .width('100%')
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

            if (this.canDismissOpenTask()) {
              Button('取消该任务')
                .width('100%')
                .height(46)
                .fontColor($r('app.color.text_secondary'))
                .backgroundColor($r('app.color.page_bg'))
                .borderRadius(23)
                .onClick(() => {
                  promptAction.showDialog({
                    title: '取消该任务',
                    message: '取消后将从待办中移除，确定继续吗？',
                    buttons: [
                      { text: '再想想', color: '#8A8A99' },
                      { text: '取消任务', color: '#FF6B81' }
                    ]
                  }).then((res: promptAction.ShowDialogSuccessResponse) => {
                    if (res.index === 1) {
                      this.dismissOpenTask();
                    }
                  });
                })
            }

            if (this.canAccept()) {
              Button('接取任务')
                .width('100%')
                .height(46)
                .fontColor($r('app.color.text_on_brand'))
                .backgroundColor($r('app.color.brand'))
                .borderRadius(23)
                .onClick(() => {
                  SpaceRepository.getInstance().acceptTask(this.taskId, this.userId, this.userName);
                  this.loadTask();
                  SoundService.feedback();
                  promptAction.showToast({ message: '已接取，可在任务 Tab 查看', duration: 1500 });
                })
            }

            if (this.canCancelTask()) {
              Button('取消任务')
                .width('100%')
                .height(46)
                .fontColor($r('app.color.text_secondary'))
                .backgroundColor($r('app.color.page_bg'))
                .borderRadius(23)
                .onClick(() => {
                  this.cancelCurrentTask();
                })
            }

            if (this.canMarkComplete()) {
              Button('已完成')
                .width('100%')
                .height(46)
                .fontColor($r('app.color.text_on_brand'))
                .backgroundColor($r('app.color.brand'))
                .borderRadius(23)
                .onClick(() => {
                  SpaceRepository.getInstance()
                    .markTaskPendingCheckIn(this.taskId, this.userId, this.userName);
                  this.loadTask();
                  SoundService.feedback();
                  promptAction.showToast({ message: '请上传打卡照片', duration: 1500 });
                })
            }

            if (this.canFinishCooking()) {
              Button('做完了')
                .width('100%')
                .height(46)
                .fontColor($r('app.color.text_on_brand'))
                .backgroundColor($r('app.color.brand'))
                .borderRadius(23)
                .onClick(() => {
                  if (this.task !== undefined && this.task.relatedRecipeId.length > 0) {
                    const title: string = this.task.title.replace('制作中：', '');
                    SpaceRepository.getInstance()
                      .markCookingPendingCheckIn(this.task.relatedRecipeId, title, this.userId, this.userName);
                    this.pathStack.pushPath({
                      name: RouteName.COOK_COMPLETE,
                      param: this.task.relatedRecipeId
                    });
                  }
                })
            }

            if (this.canCheckInCooking()) {
              Button('上传打卡照片')
                .width('100%')
                .height(46)
                .fontColor($r('app.color.text_on_brand'))
                .backgroundColor($r('app.color.brand'))
                .borderRadius(23)
                .onClick(() => {
                  if (this.task !== undefined && this.task.relatedRecipeId.length > 0) {
                    this.pathStack.pushPath({
                      name: RouteName.COOK_COMPLETE,
                      param: this.task.relatedRecipeId
                    });
                  }
                })
            }

            if (this.canPublishCheckIn()) {
              Button('发布打卡')
                .width('100%')
                .height(46)
                .fontColor($r('app.color.text_on_brand'))
                .backgroundColor($r('app.color.brand'))
                .borderRadius(23)
                .onClick(() => {
                  if (this.task !== undefined) {
                    SpaceRepository.getInstance().publishTaskCheckIn(
                      this.taskId,
                      this.task.checkInPhotoUrl,
                      this.userId,
                      this.userName,
                      '完成打卡'
                    );
                    this.loadTask();
                    SoundService.feedback();
                    promptAction.showToast({ message: '已发布，等 TA 夸夸你', duration: 1500 });
                  }
                })
            }

            if (this.canPraise()) {
              PraisePicker({
                onSelect: (phrase: string) => {
                  SpaceRepository.getInstance()
                    .praiseTask(this.taskId, this.userId, phrase, this.userName);
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
