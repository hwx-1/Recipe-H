/**
 * CookingBanner - 进行中烹饪提示条
 *
 * 作用：当存在进行中的烹饪会话时，在页面顶部展示“N 道菜进行中”提示。
 * 复用：HomePage、SpacePage 等需要提示烹饪进度的页面。
 *
 * @Prop count - 进行中会话数量(>0 才显示)
 * @Event onTap - 点击回调
 */
@Component
export struct CookingBanner {
  @Prop count: number = 0;
  onTap?: () => void;

  build() {
    if (this.count > 0) {
      Row({ space: 8 }) {
        Text('🍳')
          .fontSize(18)
        Text(`${this.count} 道菜正在进行中`)
          .fontSize($r('app.float.font_caption'))
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Text('查看 ›')
          .fontSize($r('app.float.font_caption'))
          .fontColor($r('app.color.brand'))
      }
      .width('100%')
      .padding(12)
      .backgroundColor($r('app.color.brand_light'))
      .borderRadius($r('app.float.radius_chip'))
      .onClick(() => {
        this.onTap?.();
      })
    }
  }
}
