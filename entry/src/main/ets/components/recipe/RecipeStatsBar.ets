/**
 * RecipeStatsBar - 食谱转发/点赞统计条
 *
 * 作用：紧凑展示「🔁 转发数 · ❤️ 点赞数」，监听 AppStorage 统计版本实现实时更新。
 * 复用：RecipeCard、RecipeDetailPage、RankPage 等。
 *
 * @Prop recipeId - 食谱 ID
 */
import { RecipeStatsRepository } from '../../repository/RecipeStatsRepository';

@Component
export struct RecipeStatsBar {
  @Prop recipeId: string = '';
  @StorageLink('recipeStatsVersion') private statsVersion: number = 0;

  build() {
    Row({ space: 10 }) {
      Text(`🔁 ${RecipeStatsRepository.getInstance().getStats(this.recipeId).forwardCount}`)
        .fontSize($r('app.float.font_caption'))
        .fontColor($r('app.color.text_secondary'))
      Text(`❤️ ${RecipeStatsRepository.getInstance().getStats(this.recipeId).likeCount}`)
        .fontSize($r('app.float.font_caption'))
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
  }
}
