/**
 * AppTabBar - 底部导航栏
 *
 * 作用：底部四个 Tab(食谱/小空间/任务/我的)切换，小空间与任务 Tab 支持未读/待办角标。
 * 复用：MainPage 根内容底部。
 *
 * @Prop current - 当前选中索引(0 食谱 / 1 小空间 / 2 任务 / 3 我的)
 * @Prop spaceBadge - 小空间未读数(>0 显示角标)
 * @Prop taskBadge - 任务待办数(>0 显示角标)
 * @Event onSelect - 选中回调，回传索引
 */
@Component
export struct AppTabBar {
  @Prop current: number = 0;
  @Prop spaceBadge: number = 0;
  @Prop taskBadge: number = 0;
  onSelect?: (index: number) => void;

  @Builder
  TabItem(index: number, emoji: string, label: Resource, badge: number) {
    Column({ space: 2 }) {
      if (badge > 0) {
        Badge({ count: badge, position: BadgePosition.RightTop, style: { badgeSize: 14, badgeColor: '#FF3B30' } }) {
          Text(emoji).fontSize(22)
        }
      } else {
        Text(emoji).fontSize(22)
      }
      Text(label)
        .fontSize(10)
        .fontColor(this.current === index ? $r('app.color.brand') : $r('app.color.text_secondary'))
    }
    .layoutWeight(1)
    .onClick(() => {
      this.onSelect?.(index);
    })
  }

  build() {
    Row() {
      this.TabItem(0, '🍳', $r('app.string.tab_home'), 0)
      this.TabItem(1, '💞', $r('app.string.tab_space'), this.spaceBadge)
      this.TabItem(2, '📝', $r('app.string.tab_tasks'), this.taskBadge)
      this.TabItem(3, '👤', $r('app.string.tab_profile'), 0)
    }
    .width('100%')
    .height(56)
    .padding({ top: 6, bottom: 6 })
    .backgroundColor($r('app.color.card_bg'))
    .border({ width: { top: 0.5 }, color: $r('app.color.divider') })
  }
}
