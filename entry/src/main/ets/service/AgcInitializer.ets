/**
 * AgcInitializer - AGC SDK 初始化
 *
 * 作用：在 EntryAbility 启动时读取 rawfile/agconnect-services.json 并初始化 @hw-agconnect/hmcore。
 *      配置文件缺失时仅打日志，不阻塞 App 启动（便于未配置 AGC 时本地调试食谱功能）。
 */
import { util } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { initialize, JsonTypeInfo } from '@hw-agconnect/hmcore';

const DOMAIN: number = 0x0001;
const TAG: string = 'AgcInitializer';

export class AgcInitializer {
  private static ready: boolean = false;

  /**
   * @returns 是否初始化成功
   */
  static init(context: common.Context): boolean {
    if (AgcInitializer.ready) {
      return true;
    }
    try {
      const bytes: Uint8Array = context.resourceManager.getRawFileContentSync('agconnect-services.json');
      const jsonString: string = util.TextDecoder.create('utf-8', { ignoreBOM: true })
        .decodeWithStream(bytes, { stream: false });
      initialize(context, JSON.parse(jsonString) as JsonTypeInfo);
      AgcInitializer.ready = true;
      hilog.info(DOMAIN, TAG, 'AGC initialized');
      return true;
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'AGC init skipped: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  static isReady(): boolean {
    return AgcInitializer.ready;
  }
}
