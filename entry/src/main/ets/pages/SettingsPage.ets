/**
 * SettingsPage - 设置页
 *
 * 作用：互动开关、情侣空间管理、法律文档、退出登录。
 */
import { promptAction } from '@kit.ArkUI';
import { PrefsUtil } from '../common/PrefsUtil';
import { PrefKey, RouteName } from '../common/Constants';
import { AccountService, KEY_IS_LOGGED_IN } from '../service/AccountService';
import { SpaceRepository } from '../repository/SpaceRepository';
import { rippleTransition } from '../common/transition/WaterRippleTransition';

@Component
export struct SettingsPage {
  pathStack: NavPathStack = new NavPathStack();
  @StorageLink(KEY_IS_LOGGED_IN) private isLoggedIn: boolean = false;
  @State private soundEnabled: boolean = true;

  aboutToAppear(): void {
    this.soundEnabled = PrefsUtil.getBoolean(PrefKey.SOUND_ENABLED, true);
  }

  private confirmUnbind(): void {
    promptAction.showDialog({
      title: '重置小空间',
      message: '将清除所有动态与任务，并恢复为本地演示空间。确定继续吗？',
      buttons: [
        { text: '取消', color: '#8A8A99' },
        { text: '解绑', color: '#FF6B81' }
      ]
    }).then((res: promptAction.ShowDialogSuccessResponse) => {
      if (res.index === 1) {
        SpaceRepository.getInstance().unbind('');
        SpaceRepository.getInstance().ensureLocalCoupleSpace();
        promptAction.showToast({ message: '小空间已重置', duration: 1500 });
      }
    });
  }

  @Builder
  ToggleRow(title: string, value: boolean, onChange: (v: boolean) => void) {
    Row() {
      Text(title)
        .fontSize($r('app.float.font_body'))
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: value })
        .selectedColor($r('app.color.brand'))
        .onChange((isOn: boolean) => {
          onChange(isOn);
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(12)
  }

  @Builder
  LinkRow(title: string, docType: string) {
    Row() {
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
      this.pathStack.pushPath({ name: RouteName.LEGAL, param: docType });
    })
  }

  @Builder
  ActionRow(title: string, danger: boolean, onTap: () => void) {
    Row() {
      Text(title)
        .fontSize($r('app.float.font_body'))
        .fontColor(danger ? $r('app.color.brand') : $r('app.color.text_primary'))
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
      onTap();
    })
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 12 }) {
          Text('通用')
            .fontSize($r('app.float.font_caption'))
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
          this.ToggleRow('互动提示音', this.soundEnabled, (v: boolean) => {
            this.soundEnabled = v;
            PrefsUtil.setBoolean(PrefKey.SOUND_ENABLED, v);
          })

          if (SpaceRepository.getInstance().isBound()) {
            Text('情侣空间')
              .fontSize($r('app.float.font_caption'))
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .margin({ top: 8 })
            this.ActionRow('重置小空间数据', true, () => {
              this.confirmUnbind();
            })
          }

          Text('服务与隐私')
            .fontSize($r('app.float.font_caption'))
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .margin({ top: 8 })
          this.LinkRow('用户协议', 'user')
          this.LinkRow('隐私政策', 'privacy')
          this.LinkRow('关于心语食记', 'about')

          if (this.isLoggedIn) {
            Button('退出登录')
              .width('100%')
              .height(48)
              .fontColor($r('app.color.brand'))
              .backgroundColor($r('app.color.brand_light'))
              .borderRadius(24)
              .margin({ top: 16 })
              .onClick(async () => {
                await AccountService.signOut();
                promptAction.showToast({ message: '已退出登录', duration: 1200 });
              })
          }
        }
        .width('100%')
        .padding(16)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .title('设置')
    .backgroundColor($r('app.color.page_bg'))
    .transition(rippleTransition())
  }
}
