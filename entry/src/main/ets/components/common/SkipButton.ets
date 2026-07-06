/**
 * SkipButton - 右上角跳过按钮
 *
 * 作用：启动页/引导页右上角的“跳过”胶囊按钮，点击立即结束等待进入下一步。
 * 复用：SplashPage 及后续任何带倒计时的引导页。
 *
 * @Prop seconds - 可选倒计时秒数，>0 时显示“跳过 N”
 * @Event onSkip - 点击回调
 */
@Component
export struct SkipButton {
  @Prop seconds: number = 0;
  onSkip?: () => void;

  build() {
    Row({ space: 4 }) {
      Text($r('app.string.skip'))
        .fontSize($r('app.float.font_caption'))
        .fontColor($r('app.color.text_on_brand'))
      if (this.seconds > 0) {
        Text(this.seconds.toString())
          .fontSize($r('app.float.font_caption'))
          .fontColor($r('app.color.text_on_brand'))
      }
    }
    .padding({ left: 14, right: 14, top: 6, bottom: 6 })
    .backgroundColor($r('app.color.mask'))
    .borderRadius(16)
    .onClick(() => {
      this.onSkip?.();
    })
  }
}
