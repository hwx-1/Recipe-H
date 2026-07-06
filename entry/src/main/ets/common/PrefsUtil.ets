/**
 * PrefsUtil - 轻量本地偏好存储封装
 *
 * 作用：封装 @ohos.data.preferences 的常用读写，用于协议同意状态、提示音开关等。
 * 说明：首次使用需先调用 init(context)。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { PrefKey } from './Constants';

export class PrefsUtil {
  private static store: preferences.Preferences | undefined = undefined;

  /**
   * 初始化偏好存储，建议在 EntryAbility 或首个页面启动时调用。
   */
  static init(context: common.Context): void {
    if (PrefsUtil.store === undefined) {
      PrefsUtil.store = preferences.getPreferencesSync(context, { name: PrefKey.STORE });
    }
  }

  static getString(key: string, defaultValue: string): string {
    if (PrefsUtil.store === undefined) {
      return defaultValue;
    }
    return PrefsUtil.store.getSync(key, defaultValue) as string;
  }

  static setString(key: string, value: string): void {
    if (PrefsUtil.store === undefined) {
      return;
    }
    PrefsUtil.store.putSync(key, value);
    PrefsUtil.store.flush();
  }

  static getNumber(key: string, defaultValue: number): number {
    if (PrefsUtil.store === undefined) {
      return defaultValue;
    }
    return PrefsUtil.store.getSync(key, defaultValue) as number;
  }

  static getBoolean(key: string, defaultValue: boolean): boolean {
    if (PrefsUtil.store === undefined) {
      return defaultValue;
    }
    return PrefsUtil.store.getSync(key, defaultValue) as boolean;
  }

  static setNumber(key: string, value: number): void {
    if (PrefsUtil.store === undefined) {
      return;
    }
    PrefsUtil.store.putSync(key, value);
    PrefsUtil.store.flush();
  }

  static setBoolean(key: string, value: boolean): void {
    if (PrefsUtil.store === undefined) {
      return;
    }
    PrefsUtil.store.putSync(key, value);
    PrefsUtil.store.flush();
  }
}
