/**
 * LikesPage - 我的点赞页
 *
 * 作用：展示用户点赞过的食谱(双列卡片)，点击进入详情；无点赞时展示空状态。
 *      点赞数据来自本地 LikeRepository(Preferences)，与收藏相互独立。
 * 复用：MainPage 的 navDestination 映射。
 */
import { RecipeCard } from '../components/recipe/RecipeCard';
import { EmptyState } from '../components/common/EmptyState';
import { Recipe } from '../model/Recipe';
import { RecipeRepository } from '../repository/RecipeRepository';
import { LikeRepository, LIKE_VERSION } from '../repository/LikeRepository';
import { RECIPE_STATS_VERSION } from '../repository/RecipeStatsRepository';
import { RouteName } from '../common/Constants';
import { rippleTransition } from '../common/transition/WaterRippleTransition';

@Component
export struct LikesPage {
  pathStack: NavPathStack = new NavPathStack();
  @StorageLink(LIKE_VERSION) @Watch('onLikeChanged') private likeVersion: number = 0;
  @StorageLink(RECIPE_STATS_VERSION) private statsVersion: number = 0;
  @State private list: Recipe[] = [];

  aboutToAppear(): void {
    this.reload();
  }

  private reload(): void {
    const recipeRepo: RecipeRepository = RecipeRepository.getInstance();
    recipeRepo.ensureLoaded(getContext(this));
    const ids: string[] = LikeRepository.getInstance().getAllIds();
    const result: Recipe[] = [];
    ids.forEach((id: string) => {
      const r: Recipe | undefined = recipeRepo.getById(id);
      if (r !== undefined) {
        result.push(r);
      }
    });
    this.list = result;
  }

  private onLikeChanged(): void {
    this.reload();
  }

  build() {
    NavDestination() {
      if (this.list.length === 0) {
        Column() {
          EmptyState({ emoji: '👍', message: '还没有点赞的食谱' })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Grid() {
            ForEach(this.list, (item: Recipe) => {
              GridItem() {
                RecipeCard({
                  recipe: item,
                  onCardClick: (id: string) => {
                    this.pathStack.pushPath({ name: RouteName.RECIPE_DETAIL, param: id });
                  }
                })
              }
            }, (item: Recipe) => `${item.id}_${this.likeVersion}_${this.statsVersion}`)
          }
          .columnsTemplate('1fr 1fr')
          .rowsGap(12)
          .columnsGap(12)
          .padding(16)
          .width('100%')
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
      }
    }
    .title('我的点赞')
    .backgroundColor($r('app.color.page_bg'))
    .onShown(() => {
      this.reload();
    })
    .transition(rippleTransition())
  }
}
