/**
 * PageLoadingOverlay - 页面动态加载遮罩
 *
 * 作用：页面数据请求期间覆盖显示的加载动画(LoadingProgress)，加载完成后由父组件隐藏。
 * 复用：任意需要异步加载的页面(HomePage、SpacePage、RankPage 等)。
 *
 * @Prop loading - 是否显示遮罩
 * @Prop text - 加载提示文案
 */
@Component
export struct PageLoadingOverlay {
  @Prop loading: boolean = false;
  @Prop text: string = '加载中...';

  build() {
    if (this.loading) {
      Column({ space: 12 }) {
        LoadingProgress()
          .width(48)
          .height(48)
          .color($r('app.color.brand'))
        Text(this.text)
          .fontSize($r('app.float.font_caption'))
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.page_bg'))
    }
  }
}
