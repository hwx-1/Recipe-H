/**
 * EmptyState - 通用空状态占位
 *
 * 作用：无数据时统一展示图标 + 文案 + 可选操作按钮。
 * 复用：SpacePage(未绑定/无任务)、FavoritesPage、RankPage 等。
 *
 * @Prop emoji - 占位图标(emoji)
 * @Prop message - 提示文案
 * @Prop buttonText - 可选按钮文案，为空则不显示按钮
 * @Event onButtonClick - 按钮点击回调
 */
@Component
export struct EmptyState {
  @Prop emoji: string = '🍽️';
  @Prop message: string = '还没有内容';
  @Prop buttonText: string = '';
  onButtonClick?: () => void;

  build() {
    Column({ space: 12 }) {
      Text(this.emoji)
        .fontSize(48)
      Text(this.message)
        .fontSize($r('app.float.font_body'))
        .fontColor($r('app.color.text_secondary'))
      if (this.buttonText.length > 0) {
        Button(this.buttonText)
          .fontColor($r('app.color.text_on_brand'))
          .backgroundColor($r('app.color.brand'))
          .borderRadius(20)
          .onClick(() => {
            this.onButtonClick?.();
          })
      }
    }
    .width('100%')
    .padding(24)
    .justifyContent(FlexAlign.Center)
  }
}
