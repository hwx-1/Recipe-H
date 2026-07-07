/**
 * RecipeStatsBar - 食谱转发/点赞统计条
 */
import { RecipeStatsRepository, RECIPE_STATS_VERSION } from '../../repository/RecipeStatsRepository';

@Component
export struct RecipeStatsBar {
  @Prop recipeId: string = '';
  @StorageLink(RECIPE_STATS_VERSION) statsVersion: number = 0;

  private forwardCount(): number {
    const _refresh: number = this.statsVersion;
    return RecipeStatsRepository.getInstance().getStats(this.recipeId).forwardCount;
  }

  private likeCount(): number {
    const _refresh: number = this.statsVersion;
    return RecipeStatsRepository.getInstance().getStats(this.recipeId).likeCount;
  }

  build() {
    Row({ space: 10 }) {
      Text(`🔁 ${this.forwardCount()}`)
        .fontSize($r('app.float.font_caption'))
        .fontColor($r('app.color.text_secondary'))
      Text(`❤️ ${this.likeCount()}`)
        .fontSize($r('app.float.font_caption'))
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
  }
}
