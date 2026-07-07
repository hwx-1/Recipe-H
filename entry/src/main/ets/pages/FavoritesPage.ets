/**
 * FavoritesPage - 我的收藏页
 *
 * 作用：展示用户收藏的食谱(双列卡片)，点击进入详情；无收藏时展示空状态。
 *      收藏数据来自本地 FavoriteRepository(Preferences)，无需登录即可使用。
 * 复用：MainPage 的 navDestination 映射。
 */
import { RecipeCard } from '../components/recipe/RecipeCard';
import { EmptyState } from '../components/common/EmptyState';
import { Recipe } from '../model/Recipe';
import { RecipeRepository } from '../repository/RecipeRepository';
import { FavoriteRepository, FAVORITE_VERSION } from '../repository/FavoriteRepository';
import { RECIPE_STATS_VERSION } from '../repository/RecipeStatsRepository';
import { RouteName } from '../common/Constants';
import { rippleTransition } from '../common/transition/WaterRippleTransition';

@Component
export struct FavoritesPage {
  pathStack: NavPathStack = new NavPathStack();
  @StorageLink(FAVORITE_VERSION) @Watch('onFavoriteChanged') private favoriteVersion: number = 0;
  @StorageLink(RECIPE_STATS_VERSION) private statsVersion: number = 0;
  @State private list: Recipe[] = [];

  aboutToAppear(): void {
    this.reload();
  }

  private reload(): void {
    const recipeRepo: RecipeRepository = RecipeRepository.getInstance();
    recipeRepo.ensureLoaded(getContext(this));
    const ids: string[] = FavoriteRepository.getInstance().getAllIds();
    const result: Recipe[] = [];
    ids.forEach((id: string) => {
      const r: Recipe | undefined = recipeRepo.getById(id);
      if (r !== undefined) {
        result.push(r);
      }
    });
    this.list = result;
  }

  private onFavoriteChanged(): void {
    this.reload();
  }

  build() {
    NavDestination() {
      if (this.list.length === 0) {
        Column() {
          EmptyState({ emoji: '⭐', message: '还没有收藏的食谱' })
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
            }, (item: Recipe) => `${item.id}_${this.favoriteVersion}_${this.statsVersion}`)
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
    .title('我的收藏')
    .backgroundColor($r('app.color.page_bg'))
    .onShown(() => {
      this.reload();
    })
    .transition(rippleTransition())
  }
}
