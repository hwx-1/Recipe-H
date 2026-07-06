/**
 * SpaceFeedCard - 空间动态食谱卡片
 */
import { SpaceFeedItem } from '../../model/SpaceFeedItem';

@Component
export struct SpaceFeedCard {
  @Prop item: SpaceFeedItem;
  @Prop viewerId: string = '';
  onCardClick?: (recipeId: string) => void;

  private sharerLabel(): string {
    if (this.item.sharerId === this.viewerId) {
      return '我分享了一道菜';
    }
    const name: string = this.item.sharerName.length > 0 ? this.item.sharerName : 'TA';
    return `${name} 分享了一道菜`;
  }

  build() {
    Row({ space: 12 }) {
      Text('🍽️')
        .fontSize(32)
        .width(52)
        .height(52)
        .textAlign(TextAlign.Center)
        .borderRadius(12)
        .backgroundColor($r('app.color.brand_light'))
      Column({ space: 4 }) {
        Text(this.item.recipeTitle)
          .fontSize($r('app.float.font_body'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.item.presetPhrase)
          .fontSize($r('app.float.font_caption'))
          .fontColor($r('app.color.brand'))
        Text(this.sharerLabel())
          .fontSize(10)
          .fontColor($r('app.color.text_secondary'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius($r('app.float.radius_card'))
    .onClick(() => {
      this.onCardClick?.(this.item.recipeId);
    })
  }
}
