/**
 * RecipeListPage - 分类食谱列表页
 *
 * 作用：展示某分类下食谱(双列卡片)，支持下拉刷新与统计实时联动。
 */
import { promptAction } from '@kit.ArkUI';
import { RecipeCard } from '../components/recipe/RecipeCard';
import { EmptyState } from '../components/common/EmptyState';
import { Recipe } from '../model/Recipe';
import { RecipeRepository } from '../repository/RecipeRepository';
import { RecipeStatsRepository } from '../repository/RecipeStatsRepository';
import { categoryNameById } from '../model/RecipeCategory';
import { RouteName } from '../common/Constants';
import { rippleTransition } from '../common/transition/WaterRippleTransition';

@Component
export struct RecipeListPage {
  @Prop categoryId: string = '';
  pathStack: NavPathStack = new NavPathStack();
  @StorageLink('recipeStatsVersion') private statsVersion: number = 0;
  @State private list: Recipe[] = [];
  @State private isRefreshing: boolean = false;

  aboutToAppear(): void {
    this.reload();
  }

  private reload(): void {
    const repo: RecipeRepository = RecipeRepository.getInstance();
    repo.ensureLoaded(getContext(this));
    this.list = repo.getByCategory(this.categoryId);
    RecipeStatsRepository.getInstance().bumpVersion();
  }

  build() {
    NavDestination() {
      if (this.list.length === 0) {
        EmptyState({ emoji: '🍽️', message: '该分类还没有食谱' })
      } else {
        Refresh({ refreshing: $$this.isRefreshing }) {
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
              }, (item: Recipe) => `${item.id}_${this.statsVersion}`)
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
        .width('100%')
        .height('100%')
        .onRefreshing(() => {
          this.isRefreshing = true;
          this.reload();
          this.isRefreshing = false;
          promptAction.showToast({ message: '已刷新', duration: 1000 });
        })
      }
    }
    .title(categoryNameById(this.categoryId))
    .backgroundColor($r('app.color.page_bg'))
    .onShown(() => {
      this.reload();
    })
    .transition(rippleTransition())
  }
}
