/**
 * ProfilePage - 我的(Tab)
 */
import { RouteName } from '../common/Constants';
import { FavoriteRepository } from '../repository/FavoriteRepository';
import { LikeRepository } from '../repository/LikeRepository';
import { SpaceRepository, SPACE_VERSION } from '../repository/SpaceRepository';
import { CookingSessionManager } from '../service/CookingSessionManager';
import { LocalUserService } from '../service/LocalUserService';
import {
  KEY_IS_LOGGED_IN,
  KEY_USER_NICK_NAME,
  KEY_USER_AVATAR_URI
} from '../service/AccountService';

@Component
export struct ProfilePage {
  pathStack: NavPathStack = new NavPathStack();
  @StorageLink(KEY_IS_LOGGED_IN) private isLoggedIn: boolean = false;
  @StorageLink(KEY_USER_NICK_NAME) private nickName: string = '';
  @StorageLink(KEY_USER_AVATAR_URI) private avatarUri: string = '';
  @StorageLink(SPACE_VERSION) private spaceVersion: number = 0;
  @State private favoriteCount: number = 0;
  @State private likeCount: number = 0;
  @State private taskDoneCount: number = 0;
  @State private cookDoneCount: number = 0;

  aboutToAppear(): void {
    SpaceRepository.getInstance().ensureLocalCoupleSpace();
    this.reloadStats();
  }

  private reloadStats(): void {
    this.favoriteCount = FavoriteRepository.getInstance().getAllIds().length;
    this.likeCount = LikeRepository.getInstance().getAllIds().length;
    this.cookDoneCount = CookingSessionManager.getInstance().getCompletedCount();
    this.taskDoneCount = SpaceRepository.getInstance()
      .getCompletedTaskCount(LocalUserService.getSelfId());
  }

  private subtitleText(): string {
    const partner: string = SpaceRepository.getInstance().getPartnerName(LocalUserService.getSelfId());
    const days: number = SpaceRepository.getInstance().getBoundDays();
    return `小空间 · ${partner} 和我的小空间 · 第 ${days} 天`;
  }

  @Builder
  StatCell(value: number, label: string) {
    Column({ space: 4 }) {
      Text(value.toString())
        .fontSize($r('app.float.font_subtitle'))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.brand'))
      Text(label)
        .fontSize(10)
        .fontColor($r('app.color.text_secondary'))
    }
    .layoutWeight(1)
  }

  @Builder
  EntryRow(emoji: string, title: string, route: string) {
    Row({ space: 12 }) {
      Text(emoji).fontSize(20)
      Text(title)
        .fontSize($r('app.float.font_body'))
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      Text('›')
        .fontSize(18)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(12)
    .onClick(() => {
      this.pathStack.pushPath({ name: route });
    })
  }

  build() {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        if (this.isLoggedIn && this.avatarUri.length > 0) {
          Image(this.avatarUri)
            .width(56)
            .height(56)
            .borderRadius(28)
            .objectFit(ImageFit.Cover)
            .backgroundColor($r('app.color.brand_light'))
        } else {
          Text(this.isLoggedIn ? '👤' : '🍳')
            .fontSize(28)
            .width(56)
            .height(56)
            .textAlign(TextAlign.Center)
            .borderRadius(28)
            .backgroundColor($r('app.color.brand_light'))
        }
        Column({ space: 4 }) {
          Text(this.isLoggedIn ? (this.nickName.length > 0 ? this.nickName : '华为用户') : '心语食记用户')
            .fontSize($r('app.float.font_subtitle'))
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          Text(this.subtitleText())
            .fontSize($r('app.float.font_caption'))
            .fontColor($r('app.color.text_secondary'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding(16)
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(16)
      .onClick(() => {
        if (!this.isLoggedIn) {
          this.pathStack.pushPath({ name: RouteName.LOGIN });
        }
      })

      Row() {
        this.StatCell(this.favoriteCount, '收藏')
        this.StatCell(this.likeCount, '点赞')
        this.StatCell(this.cookDoneCount, '做菜')
        this.StatCell(this.taskDoneCount, '任务')
      }
      .width('100%')
      .padding(16)
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(16)

      this.EntryRow('💞', '小空间设置', RouteName.BIND)
      this.EntryRow('⭐', '我的收藏', RouteName.FAVORITES)
      this.EntryRow('👍', '我的点赞', RouteName.LIKES)
      this.EntryRow('🏆', '人气排行', RouteName.RANK)
      this.EntryRow('⚙️', '设置', RouteName.SETTINGS)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 12 })
    .backgroundColor($r('app.color.page_bg'))
    .onVisibleAreaChange([0.0, 1.0], (isExpanding: boolean, _currentRatio: number) => {
      if (isExpanding) {
        this.reloadStats();
      }
    })
  }
}
