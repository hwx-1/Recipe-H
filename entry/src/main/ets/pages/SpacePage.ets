/**
 * SpacePage - 情侣小空间(Tab)
 *
 * 作用：顶部固定空间信息卡，下方滚动动态与待办；仅「我」的视角。
 */
import { promptAction } from '@kit.ArkUI';
import { SpaceFeedCard } from '../components/space/SpaceFeedCard';
import { SpaceTaskCard } from '../components/space/SpaceTaskCard';
import { SpaceFeedItem } from '../model/SpaceFeedItem';
import { SpaceTask, SpaceTaskType } from '../model/SpaceTask';
import { PresetPhrases } from '../common/PresetPhrases';
import { SpaceRepository, SPACE_VERSION } from '../repository/SpaceRepository';
import { LocalUserService } from '../service/LocalUserService';
import { RouteName } from '../common/Constants';

@Component
export struct SpacePage {
  pathStack: NavPathStack = new NavPathStack();
  @StorageLink(SPACE_VERSION) private spaceVersion: number = 0;
  private readonly userId: string = LocalUserService.getSelfId();
  @State private feeds: SpaceFeedItem[] = [];
  @State private tasks: SpaceTask[] = [];
  @State private isRefreshing: boolean = false;
  @State private showCreate: boolean = false;
  @State private newTitle: string = '';
  @State private newType: number = 0;
  @State private selectedPact: string = '';

  aboutToAppear(): void {
    SpaceRepository.getInstance().ensureLocalCoupleSpace();
    this.reload();
  }

  private reload(): void {
    this.feeds = SpaceRepository.getInstance().getFeedItems();
    this.tasks = SpaceRepository.getInstance().getActiveTasks();
  }

  private partnerName(): string {
    return SpaceRepository.getInstance().getPartnerName(this.userId);
  }

  private createTask(): void {
    let title: string = this.newTitle.trim();
    const types: SpaceTaskType[] = [
      SpaceTaskType.CRAVING, SpaceTaskType.ERRAND, SpaceTaskType.CUSTOM, SpaceTaskType.DAILY_PACT
    ];
    if (types[this.newType] === SpaceTaskType.DAILY_PACT) {
      title = this.selectedPact.length > 0 ? this.selectedPact : title;
    }
    if (title.length === 0) {
      promptAction.showToast({ message: '请输入或选择内容', duration: 1200 });
      return;
    }
    SpaceRepository.getInstance().createTask(types[this.newType], title, this.userId, '', '');
    this.newTitle = '';
    this.selectedPact = '';
    this.showCreate = false;
    this.reload();
    promptAction.showToast({ message: '需求已发布', duration: 1200 });
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
  CreatePanel() {
    Column({ space: 12 }) {
      Text('发布新需求')
        .fontSize($r('app.float.font_subtitle'))
        .fontWeight(FontWeight.Medium)
      TextInput({ placeholder: '例如：想吃糖醋排骨 / 买根葱', text: this.newTitle })
        .onChange((v: string) => {
          this.newTitle = v;
        })
      Row({ space: 8 }) {
        this.TypeChip(0, '😋 想吃')
        this.TypeChip(1, '🛒 跑腿')
        this.TypeChip(2, '📝 其他')
        this.TypeChip(3, '🤝 约定')
      }
      .width('100%')
      if (this.newType === 3) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(PresetPhrases.dailyPactTemplates(), (pact: string) => {
            Text(pact)
              .fontSize($r('app.float.font_caption'))
              .fontColor(this.selectedPact === pact ? $r('app.color.text_on_brand') : $r('app.color.brand'))
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .backgroundColor(this.selectedPact === pact ? $r('app.color.brand') : $r('app.color.brand_light'))
              .borderRadius(14)
              .margin({ right: 8, bottom: 8 })
              .onClick(() => {
                this.selectedPact = pact;
                this.newTitle = pact;
              })
          }, (pact: string) => pact)
        }
        .width('100%')
      }
      Row({ space: 12 }) {
        Button('取消')
          .layoutWeight(1)
          .backgroundColor($r('app.color.page_bg'))
          .fontColor($r('app.color.text_secondary'))
          .onClick(() => {
            this.showCreate = false;
          })
        Button('发布')
          .layoutWeight(1)
          .backgroundColor($r('app.color.brand'))
          .fontColor($r('app.color.text_on_brand'))
          .onClick(() => {
            this.createTask();
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(16)
  }

  @Builder
  TypeChip(index: number, label: string) {
    Text(label)
      .fontSize($r('app.float.font_caption'))
      .fontColor(this.newType === index ? $r('app.color.text_on_brand') : $r('app.color.text_secondary'))
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .backgroundColor(this.newType === index ? $r('app.color.brand') : $r('app.color.page_bg'))
      .borderRadius(14)
      .onClick(() => {
        this.newType = index;
      })
  }

  @Builder
  SectionTitle(text: string) {
    Text(text)
      .fontSize($r('app.float.font_subtitle'))
      .fontWeight(FontWeight.Medium)
      .fontColor($r('app.color.text_primary'))
      .width('100%')
      .padding({ top: 4, bottom: 4 })
      .backgroundColor($r('app.color.page_bg'))
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
            this.showCreate = !this.showCreate;
          })
        Text('⚙️')
          .fontSize(20)
          .onClick(() => {
            this.pathStack.pushPath({ name: RouteName.BIND });
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      Column({ space: 12 }) {
        this.SpaceHeaderCard()
        if (this.showCreate) {
          this.CreatePanel()
        }
        this.SectionTitle('空间动态')
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      Scroll() {
        Column({ space: 12 }) {
          if (this.feeds.length === 0) {
            Text('还没有分享动态，去食谱页转发吧')
              .fontSize($r('app.float.font_caption'))
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
          } else {
            ForEach(this.feeds, (item: SpaceFeedItem) => {
              SpaceFeedCard({
                item: item,
                viewerId: this.userId,
                onCardClick: (recipeId: string) => {
                  SpaceRepository.getInstance().markFeedRead(item.id);
                  this.pathStack.pushPath({ name: RouteName.RECIPE_DETAIL, param: recipeId });
                }
              })
            }, (item: SpaceFeedItem) => `${item.id}_${this.spaceVersion}`)
          }
        }
        .padding({ left: 16, right: 16 })
      }
      .width('100%')
      .constraintSize({ maxHeight: this.feeds.length === 0 ? 40 : 220 })
      .scrollBar(BarState.Off)

      Column() {
        this.SectionTitle('待办任务')
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      Refresh({ refreshing: $$this.isRefreshing }) {
        Scroll() {
          Column({ space: 12 }) {
            if (this.tasks.length === 0) {
              Text('目前无待办，可以点右上角发布需求')
                .fontSize($r('app.float.font_caption'))
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
            } else {
              ForEach(this.tasks, (task: SpaceTask) => {
                SpaceTaskCard({
                  task: task,
                  showUnread: true,
                  onCardClick: (taskId: string) => {
                    this.pathStack.pushPath({ name: RouteName.TASK_DETAIL, param: taskId });
                  }
                })
              }, (task: SpaceTask) => `${task.id}_${this.spaceVersion}`)
            }
          }
          .padding({ left: 16, right: 16, bottom: 24 })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
      }
      .layoutWeight(1)
      .onRefreshing(() => {
        this.isRefreshing = true;
        this.reload();
        this.isRefreshing = false;
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
