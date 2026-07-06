/**
 * CategoryGrid - 首页分类网格
 *
 * 作用：以网格形式展示 13 个场景分类入口，点击进入该分类食谱列表。
 * 复用：HomePage。
 *
 * @Prop categories - 分类列表
 * @Event onCategoryClick - 分类点击回调，回传分类 id
 */
import { RecipeCategory } from '../../model/RecipeCategory';

@Component
export struct CategoryGrid {
  @Prop categories: RecipeCategory[];
  onCategoryClick?: (id: string) => void;

  build() {
    Grid() {
      ForEach(this.categories, (item: RecipeCategory) => {
        GridItem() {
          Column({ space: 6 }) {
            Text(item.emoji)
              .fontSize(28)
              .width(52)
              .height(52)
              .borderRadius(26)
              .textAlign(TextAlign.Center)
              .backgroundColor(item.color)
            Text(item.name)
              .fontSize($r('app.float.font_caption'))
              .fontColor($r('app.color.text_primary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .onClick(() => {
            this.onCategoryClick?.(item.id);
          })
        }
      }, (item: RecipeCategory) => item.id)
    }
    .columnsTemplate('1fr 1fr 1fr 1fr')
    .rowsGap(16)
    .columnsGap(8)
    .width('100%')
  }
}
