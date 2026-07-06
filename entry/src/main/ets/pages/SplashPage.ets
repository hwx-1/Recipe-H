/**
 * SplashPage - 启动动态页
 *
 * 作用：冷启动时展示品牌动效(Logo 缩放 + 标语淡入 + 加载进度)，倒计时结束或点击右上角
 *      “跳过”后回调结束。不承载协议逻辑，仅负责品牌展示与加载过渡。
 * 复用：作为 AppRoot 的启动阶段组件。
 *
 * @Event onFinish - 动效结束/跳过时回调
 */
import { SkipButton } from '../components/common/SkipButton';
import { AppConst } from '../common/Constants';

@Component
export struct SplashPage {
  onFinish?: () => void;
  @State private logoScale: number = 0.6;
  @State private logoOpacity: number = 0;
  @State private remain: number = Math.ceil(AppConst.SPLASH_DURATION / 1000);
  private timerId: number = -1;
  private finished: boolean = false;

  aboutToAppear(): void {
    animateTo({ duration: 700, curve: Curve.EaseOut }, () => {
      this.logoScale = 1;
      this.logoOpacity = 1;
    });
    this.timerId = setInterval(() => {
      this.remain -= 1;
      if (this.remain <= 0) {
        this.finish();
      }
    }, 1000);
  }

  aboutToDisappear(): void {
    this.clearTimer();
  }

  private clearTimer(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private finish(): void {
    if (this.finished) {
      return;
    }
    this.finished = true;
    this.clearTimer();
    this.onFinish?.();
  }

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column({ space: 16 }) {
        Text('🍳')
          .fontSize(72)
          .scale({ x: this.logoScale, y: this.logoScale })
        Text($r('app.string.EntryAbility_label'))
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .opacity(this.logoOpacity)
        Text($r('app.string.splash_slogan'))
          .fontSize($r('app.float.font_body'))
          .fontColor($r('app.color.text_secondary'))
          .opacity(this.logoOpacity)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)

      Column() {
        LoadingProgress()
          .width(32)
          .height(32)
          .color($r('app.color.brand'))
      }
      .width('100%')
      .position({ x: 0, y: '82%' })
      .alignItems(HorizontalAlign.Center)

      SkipButton({
        seconds: this.remain,
        onSkip: () => {
          this.finish();
        }
      })
        .margin({ top: 44, right: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}
