/**
 * ForwardPhrasePicker - 想做了：文案 + 优先级
 */
import { PresetPhrases } from '../../common/PresetPhrases';
import { PriorityPicker } from './PriorityPicker';

@Component
export struct ForwardPhrasePicker {
  @Prop selectedPriority: number = 1;
  onSelect?: (phrase: string, priority: number) => void;
  onCancel?: () => void;
  onPrioritySelect?: (priority: number) => void;

  build() {
    Column({ space: 12 }) {
      Text('想做了')
        .fontSize($r('app.float.font_subtitle'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      PriorityPicker({
        selected: this.selectedPriority,
        onSelect: (level: number) => {
          this.onPrioritySelect?.(level);
        }
      })

      Text('选一句发给 TA')
        .fontSize($r('app.float.font_caption'))
        .fontColor($r('app.color.text_secondary'))
        .width('100%')

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(PresetPhrases.forwardPhrases(), (phrase: string) => {
          Text(phrase)
            .fontSize($r('app.float.font_caption'))
            .fontColor($r('app.color.brand'))
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor($r('app.color.brand_light'))
            .borderRadius(16)
            .margin({ right: 8, bottom: 8 })
            .onClick(() => {
              this.onSelect?.(phrase, this.selectedPriority);
            })
        }, (phrase: string) => phrase)
      }
      .width('100%')

      Button('取消')
        .width('100%')
        .backgroundColor($r('app.color.page_bg'))
        .fontColor($r('app.color.text_secondary'))
        .onClick(() => {
          this.onCancel?.();
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
}
