/**
 * SpacePage - 情侣小空间(Tab)
 *
 * 作用：上区动态卡片、下区待办任务；支持创建需求、下拉刷新、未读联动。
 */
import { promptAction } from '@kit.ArkUI';
import { EmptyState } from '../components/common/EmptyState';
import { SpaceFeedCard } from '../components/space/SpaceFeedCard';
import { SpaceTaskCard } from '../components/space/SpaceTaskCard';
import { SpaceFeedItem } from '../model/SpaceFeedItem';
import { SpaceTask, SpaceTaskType } from '../model/SpaceTask';
import { PresetPhrases } from '../common/PresetPhrases';
import { SpaceRepository, KEY_SPACE_BOUND, SPACE_VERSION } from '../repository/SpaceRepository';
import { KEY_IS_LOGGED_IN, KEY_USER_UNION_ID } from '../service/AccountService';
import { RouteName } from '../common/Constants';

@Component
export struct SpacePage {
  pathStack: NavPathStack = new NavPathStack();
  @StorageLink(KEY_SPACE_BOUND) private bound: boolean = false;
  @StorageLink(KEY_IS_LOGGED_IN) private isLoggedIn: boolean = false;
  @StorageLink(KEY_USER_UNION_ID) private userId: string = '';
  @StorageLink(SPACE_VERSION) private spaceVersion: number = 0;
  @State private feeds: SpaceFeedItem[] = [];
  @State private tasks: SpaceTask[] = [];
  @State private isRefreshing: boolean = false;
  @State private showCreate: boolean = false;
  @State private newTitle: string = '';
  @State private newType: number = 0;
  @State private selectedPact: string = '';

  aboutToAppear(): void {
    this.reload();
  }

  private reload(): void {
    this.bound = SpaceRepository.getInstance().isBound();
    this.feeds = SpaceRepository.getInstance().getFeedItems();
    this.tasks = SpaceRepository.getInstance().getActiveTasks();
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
    .margin({ bottom: 12 })
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

  build() {
    Column() {
      Row() {
        Text($r('app.string.tab_space'))
          .fontSize($r('app.float.font_title'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        if (this.bound && this.isLoggedIn) {
          Button('+ 需求')
            .height(32)
            .fontSize($r('app.float.font_caption'))
            .fontColor($r('app.color.text_on_brand'))
            .backgroundColor($r('app.color.brand'))
            .borderRadius(16)
            .onClick(() => {
              this.showCreate = !this.showCreate;
            })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      if (!this.isLoggedIn) {
        Column() {
          EmptyState({
            emoji: '🔐',
            message: '登录后即可使用情侣小空间',
            buttonText: '去登录',
            onButtonClick: () => {
              this.pathStack.pushPath({ name: RouteName.LOGIN });
            }
          })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (!this.bound) {
        Column() {
          EmptyState({
            emoji: '💌',
            message: '还没有和 TA 绑定小空间',
            buttonText: '邀请 TA 加入',
            onButtonClick: () => {
              this.pathStack.pushPath({ name: RouteName.BIND });
            }
          })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Refresh({ refreshing: $$this.isRefreshing }) {
          Scroll() {
            Column({ space: 12 }) {
              if (this.showCreate) {
                this.CreatePanel()
              }

              Row({ space: 8 }) {
                Text('💞')
                  .fontSize(20)
                Text(`和 ${SpaceRepository.getInstance().getPartnerName(this.userId)} 的小空间`)
                  .fontSize($r('app.float.font_caption'))
                  .fontColor($r('app.color.text_secondary'))
              }
              .width('100%')

              Text('空间动态')
                .fontSize($r('app.float.font_subtitle'))
                .fontWeight(FontWeight.Medium)
                .width('100%')
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

              Text('待办任务')
                .fontSize($r('app.float.font_subtitle'))
                .fontWeight(FontWeight.Medium)
                .width('100%')
                .margin({ top: 8 })
              if (this.tasks.length === 0) {
                Text('目前无待办，可以想想做什么或者买什么啦')
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
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}
