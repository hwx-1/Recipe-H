/**
 * SpaceTaskCard - 空间任务卡片
 */
import { SpaceTask, SpaceTaskType } from '../../model/SpaceTask';
import { SpaceRepository } from '../../repository/SpaceRepository';

@Component
export struct SpaceTaskCard {
  @Prop task: SpaceTask;
  @Prop viewerId: string = '';
  @Prop showUnread: boolean = false;
  onCardClick?: (taskId: string) => void;

  private priorityLabel(): string {
    if (this.task.priority === 1) {
      return '一级';
    }
    if (this.task.priority === 2) {
      return '二级';
    }
    return '三级';
  }

  private statusText(): string {
    if (this.viewerId.length > 0) {
      return SpaceRepository.getInstance().getTaskStatusLabel(this.task, this.viewerId);
    }
    return SpaceRepository.getInstance().getTaskStatusLabel(this.task, '');
  }

  private typeEmoji(): string {
    if (this.task.type === SpaceTaskType.RECIPE_DONE || this.task.type === SpaceTaskType.RECIPE_COOKING) {
      return '🍳';
    }
    if (this.task.type === SpaceTaskType.RECIPE_FORWARD) {
      return '💡';
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
        Row({ space: 6 }) {
          Text(`[${this.priorityLabel()}]`)
            .fontSize(10)
            .fontColor($r('app.color.brand'))
          Text(this.task.title)
            .fontSize($r('app.float.font_body'))
            .fontColor($r('app.color.text_primary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')
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
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(16)
    .onClick(() => {
      this.onCardClick?.(this.task.id);
    })
  }
}
