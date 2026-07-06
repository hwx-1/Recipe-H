/**
 * AgreementPage - 用户须知/协议同意页
 *
 * 作用：首次进入 App 时展示，必须勾选“同意《用户协议》《隐私政策》”后方可继续。
 *      未勾选时“同意并继续”按钮禁用；用户可查看两份协议全文。
 * 复用：AppRoot 的协议阶段组件。
 *
 * @Event onAgree - 用户同意并继续
 * @Event onDisagree - 用户拒绝(退出应用)
 */
import { AgreementCheckbox } from '../components/common/AgreementCheckbox';
import { LegalTexts } from '../common/LegalTexts';

@Component
export struct AgreementPage {
  onAgree?: () => void;
  onDisagree?: () => void;
  @State private checked: boolean = false;
  @State private viewingTitle: string = '';
  @State private viewingContent: string = '';
  @State private showDoc: boolean = false;

  private openDoc(title: string, content: string): void {
    this.viewingTitle = title;
    this.viewingContent = content;
    this.showDoc = true;
  }

  build() {
    Stack() {
      Column() {
        Text($r('app.string.agreement_title'))
          .fontSize($r('app.float.font_title'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .margin({ top: 60, bottom: 20 })

        Scroll() {
          Text($r('app.string.agreement_intro'))
            .fontSize($r('app.float.font_body'))
            .fontColor($r('app.color.text_secondary'))
            .lineHeight(24)
        }
        .layoutWeight(1)
        .align(Alignment.TopStart)

        AgreementCheckbox({
          checked: this.checked,
          onViewUserAgreement: () => {
            this.openDoc('用户协议', LegalTexts.userAgreement());
          },
          onViewPrivacy: () => {
            this.openDoc('隐私政策', LegalTexts.privacyPolicy());
          }
        })
          .margin({ top: 12, bottom: 16 })

        Button($r('app.string.agreement_confirm'))
          .width('100%')
          .height(48)
          .fontColor($r('app.color.text_on_brand'))
          .backgroundColor(this.checked ? $r('app.color.brand') : $r('app.color.brand_light'))
          .borderRadius(24)
          .enabled(this.checked)
          .onClick(() => {
            this.onAgree?.();
          })

        Button($r('app.string.agreement_disagree'))
          .width('100%')
          .height(44)
          .fontColor($r('app.color.text_secondary'))
          .backgroundColor(Color.Transparent)
          .margin({ top: 4, bottom: 20 })
          .onClick(() => {
            this.onDisagree?.();
          })
      }
      .width('100%')
      .height('100%')
      .padding({ left: 24, right: 24 })
      .backgroundColor($r('app.color.page_bg'))

      if (this.showDoc) {
        this.DocOverlay()
      }
    }
    .width('100%')
    .height('100%')
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
