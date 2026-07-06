/**
 * LoginPage - 华为账号登录页
 */
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { AgreementCheckbox } from '../components/common/AgreementCheckbox';
import { LegalTexts } from '../common/LegalTexts';
import { AccountService } from '../service/AccountService';
import { AgcInitializer } from '../service/AgcInitializer';
import { rippleTransition } from '../common/transition/WaterRippleTransition';

@Component
export struct LoginPage {
  pathStack: NavPathStack = new NavPathStack();
  @State private agreed: boolean = false;
  @State private loading: boolean = false;
  @State private showDoc: boolean = false;
  @State private viewingTitle: string = '';
  @State private viewingContent: string = '';

  private openDoc(title: string, content: string): void {
    this.viewingTitle = title;
    this.viewingContent = content;
    this.showDoc = true;
  }

  private async doLogin(): Promise<void> {
    if (!this.agreed) {
      promptAction.showToast({ message: '请先勾选用户协议', duration: 1500 });
      return;
    }
    if (!AgcInitializer.isReady()) {
      promptAction.showToast({
        message: 'AGC 未配置，请按 docs/AGC_SETUP.md 完成配置',
        duration: 2500
      });
      return;
    }
    this.loading = true;
    try {
      const context = getContext(this) as common.Context;
      const user = await AccountService.signIn(context);
      promptAction.showToast({ message: `欢迎，${user.nickName.length > 0 ? user.nickName : '用户'}`, duration: 1500 });
      this.pathStack.pop();
    } catch (err) {
      const msg: string = (err instanceof Error) ? err.message :
        AccountService.errorMessage(err as BusinessError);
      promptAction.showToast({ message: msg, duration: 2500 });
    } finally {
      this.loading = false;
    }
  }

  build() {
    NavDestination() {
      Stack() {
        Column({ space: 20 }) {
          Text('🍳')
            .fontSize(64)
            .margin({ top: 48 })
          Text('使用华为账号登录')
            .fontSize($r('app.float.font_subtitle'))
            .fontColor($r('app.color.text_primary'))
          Text('登录后可绑定情侣空间、发布需求与任务打卡')
            .fontSize($r('app.float.font_caption'))
            .fontColor($r('app.color.text_secondary'))
            .textAlign(TextAlign.Center)
            .padding({ left: 32, right: 32 })

          if (!AgcInitializer.isReady()) {
            Text('⚠️ 尚未检测到 agconnect-services.json\n请按 docs/AGC_SETUP.md 配置 AGC')
              .fontSize($r('app.float.font_caption'))
              .fontColor($r('app.color.brand'))
              .textAlign(TextAlign.Center)
              .padding({ left: 24, right: 24 })
              .lineHeight(20)
          }

          AgreementCheckbox({
            checked: $agreed,
            onViewUserAgreement: () => {
              this.openDoc('用户协议', LegalTexts.userAgreement());
            },
            onViewPrivacy: () => {
              this.openDoc('隐私政策', LegalTexts.privacyPolicy());
            }
          })
            .padding({ left: 24, right: 24 })

          Button(this.loading ? '登录中...' : '华为账号登录')
            .width('80%')
            .height(48)
            .fontColor($r('app.color.text_on_brand'))
            .backgroundColor(this.agreed ? $r('app.color.brand') : $r('app.color.brand_light'))
            .borderRadius(24)
            .enabled(this.agreed && !this.loading)
            .onClick(() => {
              this.doLogin();
            })

          Text('个人开发者使用标准登录(UnionID)，无需企业认证')
            .fontSize(10)
            .fontColor($r('app.color.text_secondary'))
            .textAlign(TextAlign.Center)
            .padding({ left: 32, right: 32 })
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Center)

        if (this.showDoc) {
          this.DocOverlay()
        }
      }
      .width('100%')
      .height('100%')
    }
    .title('登录')
    .backgroundColor($r('app.color.page_bg'))
    .transition(rippleTransition())
  }

  @Builder
  DocOverlay() {
    Column() {
      Row() {
        Text(this.viewingTitle)
          .fontSize($r('app.float.font_subtitle'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text('✕')
          .fontSize(18)
          .onClick(() => {
            this.showDoc = false;
          })
      }
      .width('100%')
      .margin({ bottom: 12 })

      Scroll() {
        Text(this.viewingContent)
          .fontSize($r('app.float.font_body'))
          .fontColor($r('app.color.text_secondary'))
          .lineHeight(22)
      }
      .layoutWeight(1)
      .align(Alignment.TopStart)
    }
    .width('86%')
    .height('70%')
    .padding(20)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(16)
  }
}
