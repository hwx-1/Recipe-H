/**
 * CookingBanner - 待打卡提醒条
 *
 * 作用：当存在待上传打卡图的烹饪任务时，在页面顶部展示提示。
 */
@Component
export struct CookingBanner {
  @Prop count: number = 0;
  onTap?: () => void;

  build() {
    if (this.count > 0) {
      Row({ space: 8 }) {
        Text('📷')
          .fontSize(18)
        Text(`${this.count} 道菜待打卡上传`)
          .fontSize($r('app.float.font_caption'))
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Text('去上传 ›')
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
