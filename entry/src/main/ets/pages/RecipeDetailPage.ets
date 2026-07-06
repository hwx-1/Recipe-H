/**
 * RecipeDetailPage - 食谱详情页
 *
 * 作用：展示食谱封面、用料、步骤与小贴士，提供“开始做/做完了”入口(打卡后自动生成
 *      recipe_done 任务)与“转到空间/点赞”动作(占位，待接入情侣空间)。作为 Navigation 子页面。
 * 复用：MainPage 的 navDestination 映射。
 *
 * @Prop recipeId - 食谱 ID(来自路由参数)
 * @Prop pathStack - Navigation 路由栈
 */
import { promptAction } from '@kit.ArkUI';
import { Recipe, RecipeStep, Ingredient } from '../model/Recipe';
import { RecipeRepository } from '../repository/RecipeRepository';
import { FavoriteRepository } from '../repository/FavoriteRepository';
import { LikeRepository } from '../repository/LikeRepository';
import { RecipeStatsRepository } from '../repository/RecipeStatsRepository';
import { RecipeStatsBar } from '../components/recipe/RecipeStatsBar';
import { ForwardPhrasePicker } from '../components/space/ForwardPhrasePicker';
import { CookingSessionManager } from '../service/CookingSessionManager';
import { SpaceRepository } from '../repository/SpaceRepository';
import { LocalUserService } from '../service/LocalUserService';
import { SoundService } from '../service/SoundService';
import { rippleTransition } from '../common/transition/WaterRippleTransition';

@Component
export struct RecipeDetailPage {
  @Prop recipeId: string = '';
  pathStack: NavPathStack = new NavPathStack();
  @State private recipe: Recipe | undefined = undefined;
  @State private cooking: boolean = false;
  @State private favorite: boolean = false;
  @State private liked: boolean = false;
  @State private showForwardPicker: boolean = false;

  aboutToAppear(): void {
    SpaceRepository.getInstance().ensureLocalCoupleSpace();
    const repo: RecipeRepository = RecipeRepository.getInstance();
    repo.ensureLoaded(getContext(this));
    this.recipe = repo.getById(this.recipeId);
    this.favorite = FavoriteRepository.getInstance().isFavorite(this.recipeId);
    this.liked = LikeRepository.getInstance().isLiked(this.recipeId);
    this.cooking = CookingSessionManager.getInstance().isCooking(this.recipeId);
  }

  private confirmStartCooking(): void {
    if (this.recipe === undefined) {
      return;
    }
    const title: string = this.recipe.title;
    promptAction.showDialog({
      title: '开始做这道菜',
      message: `确定现在开始做《${title}》吗？开始后会为它单独计时并在超时时提醒你。`,
      buttons: [
        { text: '再想想', color: '#8A8A99' },
        { text: '开始', color: '#FF6B81' }
      ]
    }).then((res: promptAction.ShowDialogSuccessResponse) => {
      if (res.index === 1) {
        this.startCooking();
      }
    });
  }

  private startCooking(): void {
    if (this.recipe === undefined) {
      return;
    }
    CookingSessionManager.getInstance().start(this.recipe);
    this.cooking = true;
    this.toast('已开始，做完记得点“做完了”打卡');
  }

  private confirmForward(): void {
    if (this.recipe === undefined) {
      return;
    }
    const title: string = this.recipe.title;
    promptAction.showDialog({
      title: '转发到情侣空间',
      message: `把《${title}》分享到你们的小空间吗？TA 会在空间动态里看到这道菜。`,
      buttons: [
        { text: '取消', color: '#8A8A99' },
        { text: '继续', color: '#FF6B81' }
      ]
    }).then((res: promptAction.ShowDialogSuccessResponse) => {
      if (res.index === 1) {
        this.showForwardPicker = true;
      }
    });
  }

  private forwardWithPhrase(phrase: string): void {
    if (this.recipe === undefined) {
      return;
    }
    SpaceRepository.getInstance()
      .addFeedShare(this.recipeId, this.recipe.title, phrase,
        LocalUserService.getSelfId(), LocalUserService.getSelfName());
    RecipeStatsRepository.getInstance().addForward(this.recipeId);
    this.showForwardPicker = false;
    SoundService.feedback();
    this.toast('已分享到情侣空间');
  }

  private finishCooking(): void {
    CookingSessionManager.getInstance().completeByRecipe(this.recipeId);
    this.cooking = false;
    if (this.recipe !== undefined) {
      SpaceRepository.getInstance()
        .createRecipeDoneTask(this.recipeId, this.recipe.title, LocalUserService.getSelfId());
      this.toast('完成打卡！已通知 TA');
    } else {
      this.toast('完成打卡！');
    }
  }

  private abandonCooking(): void {
    CookingSessionManager.getInstance().abandonByRecipe(this.recipeId);
    this.cooking = false;
    this.toast('已放弃本次');
  }

  private toggleFavorite(): void {
    this.favorite = FavoriteRepository.getInstance().toggle(this.recipeId);
    SoundService.feedback();
    this.toast(this.favorite ? '已收藏' : '已取消收藏');
  }

  private toggleLike(): void {
    const wasLiked: boolean = this.liked;
    this.liked = LikeRepository.getInstance().toggle(this.recipeId);
    RecipeStatsRepository.getInstance().applyLikeChange(this.recipeId, this.liked, wasLiked);
    SoundService.feedback();
    this.toast(this.liked ? '已点赞' : '已取消点赞');
  }

  private toast(msg: string): void {
    promptAction.showToast({ message: msg, duration: 1500 });
  }

  build() {
    NavDestination() {
      if (this.recipe !== undefined) {
        Stack({ alignContent: Alignment.Bottom }) {
          Scroll() {
            Column({ space: 16 }) {
              Stack({ alignContent: Alignment.TopEnd }) {
                Stack() {
                  Text(this.recipe.emoji.length > 0 ? this.recipe.emoji : '🍽️')
                    .fontSize(88)
                }
                .width('100%')
                .height(200)
                .backgroundColor($r('app.color.brand_light'))
                Text(this.favorite ? '❤️' : '🤍')
                  .fontSize(22)
                  .padding(8)
                  .margin({ top: 12, right: 12 })
                  .borderRadius(20)
                  .backgroundColor($r('app.color.mask'))
                  .onClick(() => {
                    this.toggleFavorite();
                  })
              }
              .width('100%')
              .height(200)

              Column({ space: 12 }) {
                Text(this.recipe.title)
                  .fontSize($r('app.float.font_title'))
                  .fontWeight(FontWeight.Bold)
                  .fontColor($r('app.color.text_primary'))

                Row({ space: 16 }) {
                  Text(`⏱ ${this.recipe.timeMinutes}分钟`)
                    .fontSize($r('app.float.font_caption'))
                    .fontColor($r('app.color.text_secondary'))
                  Text(`🍽 ${this.recipe.servings}人份`)
                    .fontSize($r('app.float.font_caption'))
                    .fontColor($r('app.color.text_secondary'))
                  Blank()
                  Row({ space: 4 }) {
                    Text(this.liked ? '👍' : '👍🏻')
                      .fontSize(16)
                    Text(this.liked ? '已赞' : '点赞')
                      .fontSize($r('app.float.font_caption'))
                      .fontColor(this.liked ? $r('app.color.brand') : $r('app.color.text_secondary'))
                  }
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .borderRadius(14)
                  .backgroundColor(this.liked ? $r('app.color.brand_light') : $r('app.color.page_bg'))
                  .onClick(() => {
                    this.toggleLike();
                  })
                }
                .width('100%')

                RecipeStatsBar({ recipeId: this.recipe.id })
                  .margin({ top: 4 })

                this.SectionTitle('用料')
                ForEach(this.recipe.ingredients, (ing: Ingredient) => {
                  Row() {
                    Text(ing.name)
                      .fontSize($r('app.float.font_body'))
                      .fontColor($r('app.color.text_primary'))
                      .layoutWeight(1)
                    Text(ing.amount)
                      .fontSize($r('app.float.font_body'))
                      .fontColor($r('app.color.text_secondary'))
                  }
                  .width('100%')
                  .padding({ top: 6, bottom: 6 })
                  .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })
                }, (ing: Ingredient) => ing.name)

                this.SectionTitle('做法步骤')
                ForEach(this.recipe.steps, (step: RecipeStep) => {
                  Row({ space: 10 }) {
                    Text(step.order.toString())
                      .fontSize($r('app.float.font_caption'))
                      .fontColor($r('app.color.text_on_brand'))
                      .width(24)
                      .height(24)
                      .textAlign(TextAlign.Center)
                      .borderRadius(12)
                      .backgroundColor($r('app.color.brand'))
                    Text(step.text)
                      .fontSize($r('app.float.font_body'))
                      .fontColor($r('app.color.text_primary'))
                      .layoutWeight(1)
                      .lineHeight(22)
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Top)
                }, (step: RecipeStep) => step.order.toString())

                if (this.recipe.tips !== undefined && this.recipe.tips.length > 0) {
                  this.SectionTitle('小贴士')
                  Text(this.recipe.tips)
                    .fontSize($r('app.float.font_body'))
                    .fontColor($r('app.color.text_secondary'))
                    .lineHeight(22)
                    .padding(12)
                    .width('100%')
                    .borderRadius(12)
                    .backgroundColor($r('app.color.brand_light'))
                }
              }
              .alignItems(HorizontalAlign.Start)
              .padding({ left: 16, right: 16, bottom: 96 })
            }
          }
          .width('100%')
          .height('100%')
          .scrollBar(BarState.Off)

          this.BottomBar()

          if (this.showForwardPicker) {
            Column() {
              Blank()
              ForwardPhrasePicker({
                onSelect: (phrase: string) => {
                  this.forwardWithPhrase(phrase);
                },
                onCancel: () => {
                  this.showForwardPicker = false;
                }
              })
            }
            .width('100%')
            .height('100%')
            .backgroundColor($r('app.color.mask'))
            .justifyContent(FlexAlign.End)
          }
        }
      }
    }
    .title('食谱详情')
    .backgroundColor($r('app.color.page_bg'))
    .onShown(() => {
      this.liked = LikeRepository.getInstance().isLiked(this.recipeId);
    })
    .transition(rippleTransition())
  }

  @Builder
  SectionTitle(text: string) {
    Text(text)
      .fontSize($r('app.float.font_subtitle'))
      .fontWeight(FontWeight.Medium)
      .fontColor($r('app.color.text_primary'))
      .margin({ top: 8 })
  }

  @Builder
  BottomBar() {
    Column({ space: 6 }) {
      Row({ space: 12 }) {
        Button('转到空间')
          .layoutWeight(1)
          .height(46)
          .fontColor($r('app.color.brand'))
          .backgroundColor($r('app.color.brand_light'))
          .borderRadius(23)
          .onClick(() => {
            this.confirmForward();
          })
        Button(this.cooking ? '做完了' : '开始做')
          .layoutWeight(1)
          .height(46)
          .fontColor($r('app.color.text_on_brand'))
          .backgroundColor($r('app.color.brand'))
          .borderRadius(23)
          .onClick(() => {
            if (this.cooking) {
              this.finishCooking();
            } else {
              this.confirmStartCooking();
            }
          })
      }
      .width('100%')

      if (this.cooking) {
        Text('放弃本次')
          .fontSize($r('app.float.font_caption'))
          .fontColor($r('app.color.text_secondary'))
          .onClick(() => {
            this.abandonCooking();
          })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
  }
}
