/**
 * AgreementCheckbox - 用户协议勾选区
 *
 * 作用：展示“我已阅读并同意《用户协议》《隐私政策》”，勾选状态通过 @Link 双向绑定。
 *      协议名可点击查看全文。
 * 复用：AgreementPage(首次)、LoginPage(登录前再次确认)。
 *
 * @Link checked - 勾选状态(双向)
 * @Event onViewUserAgreement - 点击《用户协议》
 * @Event onViewPrivacy - 点击《隐私政策》
 */
@Component
export struct AgreementCheckbox {
  @Link checked: boolean;
  onViewUserAgreement?: () => void;
  onViewPrivacy?: () => void;

  build() {
    Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center }) {
      Checkbox()
        .select(this.checked)
        .selectedColor($r('app.color.brand'))
        .width(20)
        .height(20)
        .onChange((value: boolean) => {
          this.checked = value;
        })
      Text($r('app.string.agreement_checkbox'))
        .fontSize($r('app.float.font_caption'))
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.user_agreement'))
        .fontSize($r('app.float.font_caption'))
        .fontColor($r('app.color.brand'))
        .onClick(() => {
          this.onViewUserAgreement?.();
        })
      Text($r('app.string.privacy_policy'))
        .fontSize($r('app.float.font_caption'))
        .fontColor($r('app.color.brand'))
        .onClick(() => {
          this.onViewPrivacy?.();
        })
    }
    .width('100%')
  }
}
