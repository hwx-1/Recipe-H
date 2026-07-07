/**
 * RankPage - 人气排行页
 *
 * 作用：转发榜/点赞榜 TOP10，按本地 RecipeStatsRepository 实时排序，支持下拉刷新。
 */
import { promptAction } from '@kit.ArkUI';
import { EmptyState } from '../components/common/EmptyState';
import { Recipe } from '../model/Recipe';
import { RecipeRepository } from '../repository/RecipeRepository';
import { RecipeStatsRepository } from '../repository/RecipeStatsRepository';
import { RouteName } from '../common/Constants';
import { rippleTransition } from '../common/transition/WaterRippleTransition';

@Component
export struct RankPage {
  pathStack: NavPathStack = new NavPathStack();
  @StorageLink('recipeStatsVersion') @Watch('onStatsVersionChanged') private statsVersion: number = 0;
  @State private tab: number = 0;
  @State private list: Recipe[] = [];
  @State private isRefreshing: boolean = false;
  @State private isEmpty: boolean = true;

  aboutToAppear(): void {
    this.reload();
  }

  private reload(): void {
    const repo: RecipeRepository = RecipeRepository.getInstance();
    repo.ensureLoaded(getContext(this));
    const all: Recipe[] = repo.getAll();
    const ids: string[] = all.map((r: Recipe) => r.id);
    const statsRepo: RecipeStatsRepository = RecipeStatsRepository.getInstance();
    const rankedIds: string[] = this.tab === 0 ? statsRepo.rankByForward(ids) : statsRepo.rankByLike(ids);
    const result: Recipe[] = [];
    let anyStat: boolean = false;
    rankedIds.forEach((id: string) => {
      const stats = statsRepo.getStats(id);
      const count: number = this.tab === 0 ? stats.forwardCount : stats.likeCount;
      if (count > 0) {
        anyStat = true;
      }
      const found: Recipe | undefined = all.find((r: Recipe) => r.id === id);
      if (found !== undefined && count > 0) {
        result.push(found);
      }
    });
    this.isEmpty = !anyStat;
    this.list = result.slice(0, 10);
  }

  private onStatsVersionChanged(): void {
    this.reload();
  }

  @Builder
  TabHeader() {
    Row() {
      this.TabButton(0, '转发榜')
      this.TabButton(1, '点赞榜')
    }
    .width('100%')
    .padding(8)
  }

  @Builder
  TabButton(index: number, label: string) {
    Text(label)
      .fontSize($r('app.float.font_body'))
      .fontColor(this.tab === index ? $r('app.color.text_on_brand') : $r('app.color.text_secondary'))
      .backgroundColor(this.tab === index ? $r('app.color.brand') : Color.Transparent)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .borderRadius(18)
      .onClick(() => {
        this.tab = index;
        this.reload();
      })
  }

  build() {
    NavDestination() {
      Column() {
        this.TabHeader()
        if (this.isEmpty) {
          Column() {
            EmptyState({
              emoji: '🏆',
              message: this.tab === 0 ? '还没有转发数据，去详情页转发到空间吧' : '还没有点赞数据，去给喜欢的菜点个赞吧'
            })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          Refresh({ refreshing: $$this.isRefreshing }) {
            List({ space: 8 }) {
              ForEach(this.list, (item: Recipe, index: number) => {
                ListItem() {
                  Row({ space: 12 }) {
                    Text((index + 1).toString())
                      .fontSize($r('app.float.font_subtitle'))
                      .fontWeight(FontWeight.Bold)
                      .fontColor(index < 3 ? $r('app.color.brand') : $r('app.color.text_secondary'))
                      .width(28)
                      .textAlign(TextAlign.Center)
                    Text(item.title)
                      .fontSize($r('app.float.font_body'))
                      .fontColor($r('app.color.text_primary'))
                      .layoutWeight(1)
                    Text(this.tab === 0 ?
                      `🔁 ${RecipeStatsRepository.getInstance().getStats(item.id).forwardCount}` :
                      `❤️ ${RecipeStatsRepository.getInstance().getStats(item.id).likeCount}`)
                      .fontSize($r('app.float.font_caption'))
                      .fontColor($r('app.color.text_secondary'))
                  }
                  .width('100%')
                  .padding(14)
                  .backgroundColor($r('app.color.card_bg'))
                  .borderRadius(12)
                  .onClick(() => {
                    this.pathStack.pushPath({ name: RouteName.RECIPE_DETAIL, param: item.id });
                  })
                }
              }, (item: Recipe) => `${item.id}_${this.statsVersion}_${this.tab}`)
            }
            .layoutWeight(1)
            .padding({ left: 16, right: 16 })
            .scrollBar(BarState.Off)
          }
          .layoutWeight(1)
          .onRefreshing(() => {
            this.isRefreshing = true;
            this.reload();
            this.isRefreshing = false;
            promptAction.showToast({ message: '已刷新', duration: 1000 });
          })
        }
      }
      .width('100%')
      .height('100%')
    }
    .title('人气排行')
    .backgroundColor($r('app.color.page_bg'))
    .onShown(() => {
      this.reload();
    })
    .transition(rippleTransition())
  }
}
