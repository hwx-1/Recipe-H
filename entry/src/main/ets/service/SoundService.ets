/**
 * SoundService - 互动反馈
 *
 * 作用：点赞/收藏/夸赞等操作成功时，按设置页开关触发短振动反馈。
 */
import { vibrator } from '@kit.SensorServiceKit';
import { PrefsUtil } from '../common/PrefsUtil';
import { PrefKey } from '../common/Constants';

export class SoundService {
  static feedback(): void {
    if (!PrefsUtil.getBoolean(PrefKey.SOUND_ENABLED, true)) {
      return;
    }
    try {
      vibrator.startVibration({
        type: 'time',
        duration: 40
      }, {
        usage: 'touch'
      });
    } catch (_err) {
      // 模拟器可能不支持振动，忽略
    }
  }
}
