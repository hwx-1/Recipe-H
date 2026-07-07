/**
 * HomePage - 首页(食谱)
 *
 * 作用：展示今日推荐、分类网格、人气排行预览；支持下拉刷新与统计实时联动。
 */
import { promptAction } from '@kit.ArkUI';
import { CategoryGrid } from '../components/recipe/CategoryGrid';
import { RecipeCard } from '../components/recipe/RecipeCard';
import { CookingBanner } from '../components/recipe/CookingBanner';
import { PageLoadingOverlay } from '../components/common/PageLoadingOverlay';
import { RECIPE_CATEGORIES } from '../model/RecipeCategory';
import { Recipe } from '../model/Recipe';
import { RecipeRepository } from '../repository/RecipeRepository';
import { RecipeStatsRepository } from '../repository/RecipeStatsRepository';
import { RouteName } from '../common/Constants';
import { SpaceRepository, SPACE_VERSION } from '../repository/SpaceRepository';
import { LocalUserService } from '../service/LocalUserService';

@Component
export struct HomePage {
  pathStack: NavPathStack = new NavPathStack();
  onSwitchTab?: (index: number) => void;
  @StorageLink(SPACE_VERSION) @Watch('onSpaceDataChanged') private spaceVersion: number = 0;
  @StorageLink('recipeStatsVersion') @Watch('onStatsVersionChanged') private statsVersion: number = 0;
  @State private pendingCheckInCount: number = 0;
  @State private recommended: Recipe[] = [];
  @State private rankPreview: Recipe[] = [];
  @State private loading: boolean = true;
  @State private isRefreshing: boolean = false;

  aboutToAppear(): void {
    this.loadData();
    this.refreshCheckInCount();
  }

  private refreshCheckInCount(): void {
    this.pendingCheckInCount = SpaceRepository.getInstance()
      .getPendingCheckInTasks(LocalUserService.getSelfId()).length;
  }

  private loadData(): void {
    const repo: RecipeRepository = RecipeRepository.getInstance();
    repo.ensureLoaded(getContext(this));
    const all: Recipe[] = repo.getAll();
    this.recommended = all.slice(0, 4);
    const ids: string[] = all.map((r: Recipe) => r.id);
    const statsRepo: RecipeStatsRepository = RecipeStatsRepository.getInstance();
    const rankedIds: string[] = statsRepo.rankByForward(ids);
    const preview: Recipe[] = [];
    rankedIds.forEach((id: string) => {
      const found: Recipe | undefined = all.find((r: Recipe) => r.id === id);
      if (found !== undefined) {
        preview.push(found);
      }
    });
    this.rankPreview = preview.slice(0, 3);
    this.loading = false;
  }

  private onStatsVersionChanged(): void {
    if (!this.loading) {
      this.loadData();
    }
  }

  private onSpaceDataChanged(): void {
    this.refreshCheckInCount();
  }

  private onRefresh(): void {
    this.isRefreshing = true;
    this.loadData();
    this.isRefreshing = false;
    promptAction.showToast({ message: '已刷新', duration: 1000 });
  }

  @Builder
  RankPreviewItem(item: Recipe, index: number) {
    Row({ space: 10 }) {
      Text((index + 1).toString())
        .fontSize($r('app.float.font_body'))
        .fontWeight(FontWeight.Bold)
        .fontColor(index === 0 ? $r('app.color.brand') : $r('app.color.text_secondary'))
        .width(24)
        .textAlign(TextAlign.Center)
      Text(item.emoji.length > 0 ? item.emoji : '🍽️')
        .fontSize(20)
      Text(item.title)
        .fontSize($r('app.float.font_body'))
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(`🔁 ${RecipeStatsRepository.getInstance().getStats(item.id).forwardCount}`)
        .fontSize($r('app.float.font_caption'))
        .fontColor($r('app.color.text_secondary'))
        .key(`rank_fwd_${item.id}_${this.statsVersion}`)
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(12)
    .onClick(() => {
      this.pathStack.pushPath({ name: RouteName.RECIPE_DETAIL, param: item.id });
    })
  }

  build() {
    Stack() {
      Refresh({ refreshing: $$this.isRefreshing }) {
        Scroll() {
          Column({ space: 20 }) {
            Text($r('app.string.EntryAbility_label'))
              .fontSize($r('app.float.font_title'))
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .width('100%')
              .margin({ top: 12 })

            CookingBanner({
              count: this.pendingCheckInCount,
              onTap: () => {
                if (this.pendingCheckInCount > 0) {
                  this.onSwitchTab?.(2);
                }
              }
            })

            CategoryGrid({
              categories: RECIPE_CATEGORIES,
              onCategoryClick: (id: string) => {
                this.pathStack.pushPath({ name: RouteName.RECIPE_LIST, param: id });
              }
            })

            Row() {
              Text('人气排行')
                .fontSize($r('app.float.font_subtitle'))
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .layoutWeight(1)
              Text('查看全部 ›')
                .fontSize($r('app.float.font_caption'))
                .fontColor($r('app.color.brand'))
                .onClick(() => {
                  this.pathStack.pushPath({ name: RouteName.RANK });
                })
            }
            .width('100%')

            if (this.rankPreview.length === 0) {
              Text('还没有排行数据，转发或点赞食谱后会出现在这里')
                .fontSize($r('app.float.font_caption'))
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
            } else {
              Column({ space: 8 }) {
                ForEach(this.rankPreview, (item: Recipe, index: number) => {
                  this.RankPreviewItem(item, index)
                }, (item: Recipe) => `${item.id}_${this.statsVersion}`)
              }
              .width('100%')
            }

            Text('今日推荐')
              .fontSize($r('app.float.font_subtitle'))
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .width('100%')

            Grid() {
              ForEach(this.recommended, (item: Recipe) => {
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
            .width('100%')
          }
          .padding({ left: 16, right: 16, bottom: 24 })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .onRefreshing(() => {
        this.onRefresh();
      })

      PageLoadingOverlay({ loading: this.loading })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}
