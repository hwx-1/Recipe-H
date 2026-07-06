/**
 * RecipeCard - 食谱卡片
 *
 * 作用：展示食谱封面、标题、耗时与难度，用于食谱列表与收藏列表。
 * 复用：RecipeListPage、FavoritesPage、HomePage 推荐区。
 *
 * @Prop recipe - 食谱数据
 * @Event onCardClick - 卡片点击回调，回传食谱 id
 */
import { Recipe, RecipeDifficulty } from '../../model/Recipe';
import { RecipeStatsBar } from './RecipeStatsBar';

@Component
export struct RecipeCard {
  @Prop recipe: Recipe;
  onCardClick?: (id: string) => void;

  private difficultyText(d: RecipeDifficulty): string {
    if (d === RecipeDifficulty.EASY) {
      return '简单';
    }
    if (d === RecipeDifficulty.HARD) {
      return '进阶';
    }
    return '适中';
  }

  build() {
    Column() {
      Stack() {
        Text(this.recipe.emoji.length > 0 ? this.recipe.emoji : '🍽️')
          .fontSize(52)
      }
      .width('100%')
      .height(120)
      .borderRadius({ topLeft: 16, topRight: 16 })
      .backgroundColor($r('app.color.brand_light'))
      Column({ space: 4 }) {
        Text(this.recipe.title)
          .fontSize($r('app.float.font_subtitle'))
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 8 }) {
          Text(`⏱ ${this.recipe.timeMinutes}分钟`)
            .fontSize($r('app.float.font_caption'))
            .fontColor($r('app.color.text_secondary'))
          Text(this.difficultyText(this.recipe.difficulty))
            .fontSize($r('app.float.font_caption'))
            .fontColor($r('app.color.text_secondary'))
        }
        RecipeStatsBar({ recipeId: this.recipe.id })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(10)
    }
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius($r('app.float.radius_card'))
    .clip(true)
    .onClick(() => {
      this.onCardClick?.(this.recipe.id);
    })
  }
}
