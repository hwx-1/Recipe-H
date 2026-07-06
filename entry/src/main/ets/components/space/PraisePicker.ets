/**
 * PraisePicker - 预设夸赞文案选择器
 *
 * 作用：任务完成后，对方从系统预设文案中选择一句夸奖。
 */
import { PresetPhrases } from '../../common/PresetPhrases';

@Component
export struct PraisePicker {
  onSelect?: (phrase: string) => void;

  build() {
    Column({ space: 8 }) {
      Text('选一句夸夸 TA')
        .fontSize($r('app.float.font_subtitle'))
        .fontColor($r('app.color.text_primary'))
        .width('100%')
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(PresetPhrases.praisePhrases(), (phrase: string) => {
          Text(phrase)
            .fontSize($r('app.float.font_caption'))
            .fontColor($r('app.color.brand'))
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor($r('app.color.brand_light'))
            .borderRadius(16)
            .margin({ right: 8, bottom: 8 })
            .onClick(() => {
              this.onSelect?.(phrase);
            })
        }, (phrase: string) => phrase)
      }
      .width('100%')
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.page_bg'))
    .borderRadius(12)
  }
}
