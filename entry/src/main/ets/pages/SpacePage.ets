/**
 * SpacePage - 情侣小空间(Tab)
 */
import { promptAction } from '@kit.ArkUI';
import { PrioritySlotCards } from '../components/space/PrioritySlotCards';
import { SpaceFeedCard } from '../components/space/SpaceFeedCard';
import { SpaceFeedItem } from '../model/SpaceFeedItem';
import { SpaceRepository, SPACE_VERSION } from '../repository/SpaceRepository';
import { LocalUserService } from '../service/LocalUserService';
import { RouteName } from '../common/Constants';

@Component
export struct SpacePage {
  pathStack: NavPathStack = new NavPathStack();
  @StorageLink(SPACE_VERSION) private spaceVersion: number = 0;
  private readonly userId: string = LocalUserService.getSelfId();
  @State private feeds: SpaceFeedItem[] = [];
  @State private isRefreshing: boolean = false;

  aboutToAppear(): void {
    SpaceRepository.getInstance().ensureLocalCoupleSpace();
    this.reload();
  }

  private reload(): void {
    this.feeds = SpaceRepository.getInstance().getFeedPreview(3);
  }

  private onRefresh(): void {
    this.isRefreshing = true;
    this.reload();
    this.isRefreshing = false;
    promptAction.showToast({ message: '已刷新', duration: 1000 });
  }

  private partnerName(): string {
    return SpaceRepository.getInstance().getPartnerName(this.userId);
  }

  private openTaskDetail(taskId: string): void {
    this.pathStack.pushPath({ name: RouteName.TASK_DETAIL, param: taskId });
  }

  @Builder
  SpaceHeaderCard() {
    Column({ space: 6 }) {
      Row({ space: 10 }) {
        Text('💞')
          .fontSize(28)
        Column({ space: 4 }) {
          Text(`${this.partnerName()} 和我的小空间`)
            .fontSize($r('app.float.font_subtitle'))
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          Text(`在一起第 ${SpaceRepository.getInstance().getBoundDays()} 天`)
            .fontSize($r('app.float.font_caption'))
            .fontColor($r('app.color.brand'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(16)
  }

  @Builder
  SectionTitle(text: string) {
    Text(text)
      .fontSize($r('app.float.font_subtitle'))
      .fontWeight(FontWeight.Medium)
      .fontColor($r('app.color.text_primary'))
      .width('100%')
  }

  @Builder
  EmptyHintCard(message: string) {
    Text(message)
      .fontSize($r('app.float.font_caption'))
      .fontColor($r('app.color.text_secondary'))
      .width('100%')
      .padding(16)
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(16)
  }

  build() {
    Column() {
      Row() {
        Text($r('app.string.tab_space'))
          .fontSize($r('app.float.font_title'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Button('+ 需求')
          .height(32)
          .fontSize($r('app.float.font_caption'))
          .fontColor($r('app.color.text_on_brand'))
          .backgroundColor($r('app.color.brand'))
          .borderRadius(16)
          .margin({ right: 8 })
          .onClick(() => {
            this.pathStack.pushPath({ name: RouteName.TASK_PUBLISH, param: '1' });
          })
        Text('⚙️')
          .fontSize(20)
          .onClick(() => {
            this.pathStack.pushPath({ name: RouteName.BIND });
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      Refresh({ refreshing: $$this.isRefreshing }) {
        Scroll() {
          Column({ space: 12 }) {
            this.SpaceHeaderCard()

            PrioritySlotCards({
              viewerId: this.userId,
              onTaskClick: (taskId: string) => {
                this.openTaskDetail(taskId);
              }
            })

            Column({ space: 8 }) {
              Row() {
                this.SectionTitle('空间动态')
                Text('查看全部 ›')
                  .fontSize($r('app.float.font_caption'))
                  .fontColor($r('app.color.brand'))
                  .onClick(() => {
                    this.pathStack.pushPath({ name: RouteName.SPACE_FEED });
                  })
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)

              if (this.feeds.length === 0) {
                this.EmptyHintCard('还没有动态，双方的操作会记录在这里')
              } else {
                ForEach(this.feeds, (item: SpaceFeedItem) => {
                  SpaceFeedCard({
                    item: item,
                    viewerId: this.userId,
                    onCardClick: (recipeId: string) => {
                      SpaceRepository.getInstance().markFeedRead(item.id);
                      if (recipeId.length > 0 && !recipeId.startsWith('task_') &&
                        !recipeId.startsWith('feed_')) {
                        this.pathStack.pushPath({ name: RouteName.RECIPE_DETAIL, param: recipeId });
                      }
                    }
                  })
                }, (item: SpaceFeedItem) => `${item.id}_${this.spaceVersion}`)
              }
            }
            .width('100%')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 4, bottom: 24 })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
      .layoutWeight(1)
      .onRefreshing(() => {
        this.onRefresh();
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
    .onVisibleAreaChange([0.0, 1.0], (isExpanding: boolean, _currentRatio: number) => {
      if (isExpanding) {
        this.reload();
      }
    })
  }
}
