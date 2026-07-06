/**
 * SpaceTaskCard - 空间任务卡片
 *
 * 作用：展示单条 SpaceTask 摘要(标题、状态、类型)，点击进入详情。
 */
import { SpaceTask, SpaceTaskStatus, SpaceTaskType } from '../../model/SpaceTask';

@Component
export struct SpaceTaskCard {
  @Prop task: SpaceTask;
  @Prop showUnread: boolean = false;
  onCardClick?: (taskId: string) => void;

  private statusText(): string {
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

  private typeEmoji(): string {
    if (this.task.type === SpaceTaskType.RECIPE_DONE) {
      return '🍳';
    }
    if (this.task.type === SpaceTaskType.ERRAND) {
      return '🛒';
    }
    if (this.task.type === SpaceTaskType.CRAVING) {
      return '😋';
    }
    if (this.task.type === SpaceTaskType.DAILY_PACT) {
      return '🤝';
    }
    return '📝';
  }

  build() {
    Row({ space: 12 }) {
      Text(this.typeEmoji())
        .fontSize(24)
      Column({ space: 4 }) {
        Text(this.task.title)
          .fontSize($r('app.float.font_body'))
          .fontColor($r('app.color.text_primary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.statusText())
          .fontSize($r('app.float.font_caption'))
          .fontColor($r('app.color.text_secondary'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      if (this.showUnread && !this.task.isRead) {
        Text('●')
          .fontSize(10)
          .fontColor($r('app.color.badge'))
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius($r('app.float.radius_card'))
    .onClick(() => {
      this.onCardClick?.(this.task.id);
    })
  }
}
