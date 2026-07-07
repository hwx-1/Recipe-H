/**
 * SpaceFeedCard - 空间动态卡片
 */
import { SpaceFeedItem, SpaceFeedType } from '../../model/SpaceFeedItem';
import { SpaceRepository } from '../../repository/SpaceRepository';

@Component
export struct SpaceFeedCard {
  @Prop item: SpaceFeedItem;
  @Prop viewerId: string = '';
  @Prop showDate: boolean = false;
  onCardClick?: (relatedId: string) => void;

  private isActionFeed(): boolean {
    return this.item.feedType === SpaceFeedType.TASK_ACTION;
  }

  private mainLabel(): string {
    if (this.isActionFeed()) {
      return SpaceRepository.getInstance().getFeedActionLabel(this.item, this.viewerId);
    }
    if (this.item.sharerId === this.viewerId) {
      return '我完成了一道菜';
    }
    const name: string = this.item.sharerName.length > 0 ? this.item.sharerName : 'TA';
    return `${name} 完成了一道菜`;
  }

  private badgeText(): string {
    if (this.isActionFeed()) {
      return '动态';
    }
    return '已完成';
  }

  build() {
    Column({ space: 10 }) {
      if (this.showDate) {
        Text(SpaceRepository.getInstance().formatFeedDate(this.item.createdAt))
          .fontSize(10)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
      }

      if (this.item.photoUrl.length > 0) {
        Image(this.item.photoUrl)
          .width('100%')
          .height(180)
          .borderRadius(12)
          .objectFit(ImageFit.Cover)
          .backgroundColor($r('app.color.brand_light'))
      }

      if (!this.isActionFeed()) {
        Row() {
          Text(this.item.recipeTitle)
            .fontSize($r('app.float.font_body'))
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          Text(this.badgeText())
            .fontSize(10)
            .fontColor($r('app.color.brand'))
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor($r('app.color.brand_light'))
            .borderRadius(8)
        }
        .width('100%')

        if (this.item.presetPhrase.length > 0) {
          Text(this.item.presetPhrase)
            .fontSize($r('app.float.font_caption'))
            .fontColor($r('app.color.brand'))
            .width('100%')
        }
      } else {
        Row() {
          Text(this.mainLabel())
            .fontSize($r('app.float.font_body'))
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
          Text(this.badgeText())
            .fontSize(10)
            .fontColor($r('app.color.brand'))
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor($r('app.color.brand_light'))
            .borderRadius(8)
        }
        .width('100%')
      }

      if (!this.isActionFeed()) {
        Text(this.mainLabel())
          .fontSize(10)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(16)
    .onClick(() => {
      this.onCardClick?.(this.item.recipeId);
    })
  }
}
