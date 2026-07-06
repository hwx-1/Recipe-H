/**
 * BindPage - 小空间设置页
 */
import { promptAction } from '@kit.ArkUI';
import { SpaceRepository } from '../repository/SpaceRepository';
import { LocalUserService } from '../service/LocalUserService';
import { rippleTransition } from '../common/transition/WaterRippleTransition';

@Component
export struct BindPage {
  pathStack: NavPathStack = new NavPathStack();
  private readonly userId: string = LocalUserService.getSelfId();

  aboutToAppear(): void {
    SpaceRepository.getInstance().ensureLocalCoupleSpace();
  }

  private confirmReset(): void {
    promptAction.showDialog({
      title: '重置小空间',
      message: '将清除所有动态与任务，并恢复为本地演示空间。确定继续吗？',
      buttons: [
        { text: '取消', color: '#8A8A99' },
        { text: '重置', color: '#FF6B81' }
      ]
    }).then((res: promptAction.ShowDialogSuccessResponse) => {
      if (res.index === 1) {
        SpaceRepository.getInstance().unbind(this.userId);
        SpaceRepository.getInstance().ensureLocalCoupleSpace();
        promptAction.showToast({ message: '小空间已重置', duration: 1500 });
      }
    });
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 16 }) {
          Column({ space: 8 }) {
            Text('💞')
              .fontSize(48)
            Text(`${SpaceRepository.getInstance().getPartnerName(this.userId)} 和我的小空间`)
              .fontSize($r('app.float.font_subtitle'))
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
            Text(`在一起第 ${SpaceRepository.getInstance().getBoundDays()} 天`)
              .fontSize($r('app.float.font_caption'))
              .fontColor($r('app.color.brand'))
          }
          .width('100%')
          .padding(24)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(16)

          Button('重置小空间数据')
            .width('100%')
            .height(46)
            .fontColor($r('app.color.brand'))
            .backgroundColor($r('app.color.brand_light'))
            .borderRadius(23)
            .onClick(() => {
              this.confirmReset();
            })

          Column({ space: 8 }) {
            Text('邀请码绑定')
              .fontSize($r('app.float.font_body'))
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
            Text('接入华为账号后，可通过邀请码与另一半绑定并云端同步。')
              .fontSize($r('app.float.font_caption'))
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .lineHeight(18)
            Button('即将开放')
              .width('100%')
              .height(44)
              .fontColor($r('app.color.text_secondary'))
              .backgroundColor($r('app.color.page_bg'))
              .borderRadius(22)
              .enabled(false)
          }
          .width('100%')
          .padding(16)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(16)
        }
        .padding(16)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .title('小空间设置')
    .backgroundColor($r('app.color.page_bg'))
    .transition(rippleTransition())
  }
}
