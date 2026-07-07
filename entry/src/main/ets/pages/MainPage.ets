/**
 * MainPage - 主界面(Navigation 根容器)
 *
 * 作用：承载底部三 Tab(食谱/小空间/我的)的根内容，并作为 Navigation 路由根，
 *      通过 navDestination 映射所有子页面；子页面统一使用水波转场。
 * 复用：AppRoot 的主阶段组件。
 */
import { AppTabBar } from '../components/common/AppTabBar';
import { HomePage } from './HomePage';
import { SpacePage } from './SpacePage';
import { TasksPage } from './TasksPage';
import { ProfilePage } from './ProfilePage';
import { RecipeListPage } from './RecipeListPage';
import { RecipeDetailPage } from './RecipeDetailPage';
import { RankPage } from './RankPage';
import { BindPage } from './BindPage';
import { FavoritesPage } from './FavoritesPage';
import { LikesPage } from './LikesPage';
import { SettingsPage } from './SettingsPage';
import { LoginPage } from './LoginPage';
import { LegalDocPage } from './LegalDocPage';
import { TaskDetailPage } from './TaskDetailPage';
import { CookCompletePage } from './CookCompletePage';
import { TaskPublishPage } from './TaskPublishPage';
import { SpaceFeedListPage } from './SpaceFeedListPage';
import { RouteName, KEY_SWITCH_TAB } from '../common/Constants';
import { SpaceRepository, SPACE_VERSION } from '../repository/SpaceRepository';
import { LocalUserService } from '../service/LocalUserService';

@Component
export struct MainPage {
  @State private currentTab: number = 0;
  @State private spaceBadge: number = 0;
  @State private taskBadge: number = 0;
  @StorageLink(SPACE_VERSION) @Watch('onSpaceDataChanged') private spaceVersion: number = 0;
  @StorageLink(KEY_SWITCH_TAB) @Watch('onTabSwitchRequest') private switchTabRequest: number = -1;
  private pathStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    AppStorage.setOrCreate(KEY_SWITCH_TAB, -1);
    this.refreshBadges();
  }

  onTabSwitchRequest(): void {
    if (this.switchTabRequest >= 0 && this.switchTabRequest <= 3) {
      this.currentTab = this.switchTabRequest;
      AppStorage.setOrCreate(KEY_SWITCH_TAB, -1);
    }
  }

  onSpaceDataChanged(): void {
    this.refreshBadges();
  }

  private refreshBadges(): void {
    const userId: string = LocalUserService.getSelfId();
    this.spaceBadge = SpaceRepository.getInstance().getUnreadCount(userId);
    this.taskBadge = SpaceRepository.getInstance().getTasksTabCount(userId);
  }

  @Builder
  PageMap(name: string, param: string | Object) {
    if (name === RouteName.RECIPE_LIST) {
      RecipeListPage({ categoryId: param as string, pathStack: this.pathStack })
    } else if (name === RouteName.RECIPE_DETAIL) {
      RecipeDetailPage({ recipeId: param as string, pathStack: this.pathStack })
    } else if (name === RouteName.RANK) {
      RankPage({ pathStack: this.pathStack })
    } else if (name === RouteName.BIND) {
      BindPage({ pathStack: this.pathStack })
    } else if (name === RouteName.FAVORITES) {
      FavoritesPage({ pathStack: this.pathStack })
    } else if (name === RouteName.LIKES) {
      LikesPage({ pathStack: this.pathStack })
    } else if (name === RouteName.SETTINGS) {
      SettingsPage({ pathStack: this.pathStack })
    } else if (name === RouteName.LEGAL) {
      LegalDocPage({ docType: param as string, pathStack: this.pathStack })
    } else if (name === RouteName.LOGIN) {
      LoginPage({ pathStack: this.pathStack })
    } else if (name === RouteName.TASK_DETAIL) {
      TaskDetailPage({ taskId: param as string, pathStack: this.pathStack })
    } else if (name === RouteName.COOK_COMPLETE) {
      CookCompletePage({ recipeId: param as string, pathStack: this.pathStack })
    } else if (name === RouteName.TASK_PUBLISH) {
      TaskPublishPage({ defaultPriority: param as string, pathStack: this.pathStack })
    } else if (name === RouteName.SPACE_FEED) {
      SpaceFeedListPage({ pathStack: this.pathStack })
    }
  }

  @Builder
  RootContent() {
    Column() {
      Stack() {
        if (this.currentTab === 0) {
          HomePage({
            pathStack: this.pathStack,
            onSwitchTab: (index: number) => {
              this.currentTab = index;
            }
          })
        } else if (this.currentTab === 1) {
          SpacePage({ pathStack: this.pathStack })
        } else if (this.currentTab === 2) {
          TasksPage({ pathStack: this.pathStack })
        } else {
          ProfilePage({ pathStack: this.pathStack })
        }
      }
      .layoutWeight(1)

      AppTabBar({
        current: this.currentTab,
        spaceBadge: this.spaceBadge,
        taskBadge: this.taskBadge,
        onSelect: (index: number) => {
          this.currentTab = index;
          this.refreshBadges();
        }
      })
    }
    .width('100%')
    .height('100%')
  }

  build() {
    Navigation(this.pathStack) {
      this.RootContent()
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .navDestination(this.PageMap)
    .width('100%')
    .height('100%')
  }
}
