/**
 * BindPage - 情侣绑定页
 *
 * 作用：生成邀请码(7天)或输入对方邀请码完成 1:1 绑定；已绑定则展示状态。
 */
import { promptAction } from '@kit.ArkUI';
import { KEY_IS_LOGGED_IN, KEY_USER_NICK_NAME, KEY_USER_UNION_ID } from '../service/AccountService';
import { SpaceRepository, KEY_SPACE_BOUND } from '../repository/SpaceRepository';
import { RouteName } from '../common/Constants';
import { rippleTransition } from '../common/transition/WaterRippleTransition';

@Component
export struct BindPage {
  pathStack: NavPathStack = new NavPathStack();
  @StorageLink(KEY_IS_LOGGED_IN) private isLoggedIn: boolean = false;
  @StorageLink(KEY_SPACE_BOUND) private bound: boolean = false;
  @StorageLink(KEY_USER_UNION_ID) private userId: string = '';
  @StorageLink(KEY_USER_NICK_NAME) private userName: string = '';
  @State private inputCode: string = '';
  @State private myCode: string = '';

  aboutToAppear(): void {
    this.bound = SpaceRepository.getInstance().isBound();
    this.refreshCode();
  }

  private refreshCode(): void {
    if (!this.isLoggedIn || this.userId.length === 0 || this.bound) {
      return;
    }
    let code: string = SpaceRepository.getInstance().getMyInviteCode();
    if (code.length === 0) {
      code = SpaceRepository.getInstance().generateInviteCode(this.userId, this.userName);
    }
    this.myCode = code;
  }

  private ensureLogin(): boolean {
    if (!this.isLoggedIn) {
      promptAction.showToast({ message: '请先登录华为账号', duration: 1500 });
      this.pathStack.pushPath({ name: RouteName.LOGIN });
      return false;
    }
    return true;
  }

  build() {
    NavDestination() {
      Column({ space: 20 }) {
        if (!this.isLoggedIn) {
          EmptyStateBind()
        } else if (this.bound) {
          Column({ space: 12 }) {
            Text('💞')
              .fontSize(56)
            Text('已与 TA 绑定小空间')
              .fontSize($r('app.float.font_subtitle'))
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
            Text(`伴侣：${SpaceRepository.getInstance().getPartnerName(this.userId)}`)
              .fontSize($r('app.float.font_body'))
              .fontColor($r('app.color.text_secondary'))
            Text(`在一起第 ${SpaceRepository.getInstance().getBoundDays()} 天`)
              .fontSize($r('app.float.font_caption'))
              .fontColor($r('app.color.brand'))
            Text('解绑请前往「设置 → 解绑情侣空间」')
              .fontSize($r('app.float.font_caption'))
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: 8 })
          }
          .width('100%')
          .padding(32)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(16)
        } else {
          Column({ space: 8 }) {
            Text('我的邀请码')
              .fontSize($r('app.float.font_caption'))
              .fontColor($r('app.color.text_secondary'))
            Text(this.myCode.length > 0 ? this.myCode : '生成中...')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.brand'))
            Text('7 天内有效 · 发送给 TA 即可绑定')
              .fontSize($r('app.float.font_caption'))
              .fontColor($r('app.color.text_secondary'))
            Text('当前为本地演示模式，需在同一设备切换账号测试绑定')
              .fontSize(10)
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: 4 })
            Button('重新生成')
              .fontSize($r('app.float.font_caption'))
              .fontColor($r('app.color.brand'))
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                if (this.ensureLogin()) {
                  this.myCode = SpaceRepository.getInstance().generateInviteCode(this.userId, this.userName);
                }
              })
          }
          .width('100%')
          .padding(24)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(16)

          Column({ space: 12 }) {
            Text('输入对方的邀请码')
              .fontSize($r('app.float.font_body'))
              .fontColor($r('app.color.text_primary'))
              .width('100%')
            TextInput({ placeholder: '例如 LOVE-8848', text: this.inputCode })
              .onChange((v: string) => {
                this.inputCode = v;
              })
            Button('确认绑定')
              .width('100%')
              .height(46)
              .fontColor($r('app.color.text_on_brand'))
              .backgroundColor($r('app.color.brand'))
              .borderRadius(23)
              .onClick(() => {
                if (!this.ensureLogin()) {
                  return;
                }
                const err: string = SpaceRepository.getInstance()
                  .bindWithCode(this.inputCode, this.userId, this.userName);
                if (err.length > 0) {
                  promptAction.showToast({ message: err, duration: 2000 });
                } else {
                  this.bound = true;
                  promptAction.showToast({ message: '绑定成功！', duration: 1500 });
                  this.pathStack.pop();
                }
              })
          }
          .width('100%')
          .padding(20)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(16)
        }
      }
      .width('100%')
      .height('100%')
      .padding(16)
    }
    .title('绑定小空间')
    .backgroundColor($r('app.color.page_bg'))
    .onShown(() => {
      this.bound = SpaceRepository.getInstance().isBound();
    })
    .transition(rippleTransition())
  }
}

@Builder
function EmptyStateBind() {
  Column({ space: 12 }) {
    Text('🔐')
      .fontSize(48)
    Text('绑定小空间需要先登录')
      .fontSize($r('app.float.font_body'))
      .fontColor($r('app.color.text_secondary'))
  }
  .width('100%')
  .padding(40)
}
