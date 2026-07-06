/**
 * LegalDocPage - 法律/说明文档页
 *
 * 作用：展示用户协议、隐私政策、关于应用等全文，供设置页与协议页跳转。
 *
 * @Prop docType - 文档类型：user | privacy | about
 */
import { LegalTexts } from '../common/LegalTexts';
import { rippleTransition } from '../common/transition/WaterRippleTransition';

@Component
export struct LegalDocPage {
  @Prop docType: string = 'user';
  pathStack: NavPathStack = new NavPathStack();

  private title(): string {
    if (this.docType === 'privacy') {
      return '隐私政策';
    }
    if (this.docType === 'about') {
      return '关于心语食记';
    }
    return '用户协议';
  }

  private content(): string {
    if (this.docType === 'privacy') {
      return LegalTexts.privacyPolicy();
    }
    if (this.docType === 'about') {
      return LegalTexts.aboutApp();
    }
    return LegalTexts.userAgreement();
  }

  build() {
    NavDestination() {
      Scroll() {
        Text(this.content())
          .fontSize($r('app.float.font_body'))
          .fontColor($r('app.color.text_secondary'))
          .lineHeight(24)
          .padding(16)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .title(this.title())
    .backgroundColor($r('app.color.page_bg'))
    .transition(rippleTransition())
  }
}
