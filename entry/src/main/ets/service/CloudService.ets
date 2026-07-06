/**
 * CloudService - 云服务初始化
 *
 * 作用：在用户 AGC 认证成功后，用 authProvider 初始化 Cloud Foundation Kit，
 *      使后续 Cloud DB / Cloud Storage 请求自动携带用户身份。
 * 说明：需在 AccountService.signIn 成功之后调用。
 */
import { hilog } from '@kit.PerformanceAnalysisKit';
import { cloudCommon } from '@kit.CloudFoundationKit';
import auth from '@hw-agconnect/auth';
import { AgcInitializer } from './AgcInitializer';

const DOMAIN: number = 0x0001;
const TAG: string = 'CloudService';

export class CloudService {
  private static inited: boolean = false;

  /**
   * 使用当前登录用户的 AuthProvider 初始化云 Kit。
   * @returns 是否成功
   */
  static initCloud(): boolean {
    if (!AgcInitializer.isReady()) {
      hilog.warn(DOMAIN, TAG, 'AGC not ready, skip cloud init');
      return false;
    }
    try {
      const provider = auth.getAuthProvider();
      cloudCommon.init({
        region: cloudCommon.CloudRegion.CHINA,
        authProvider: provider
      });
      CloudService.inited = true;
      hilog.info(DOMAIN, TAG, 'CloudFoundationKit initialized');
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Cloud init failed: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  static isReady(): boolean {
    return CloudService.inited;
  }
}
