/**
 * AccountService - 华为账号登录与 AGC 认证
 *
 * 作用：封装 Account Kit 标准登录(个人开发者可用) + AGC 认证服务(hwid)，
 *      获取 UnionID/昵称/头像并写入 AppStorage，供全 App 读取登录态。
 * 前置：module.json5 配置 client_id；rawfile 放置 agconnect-services.json；AGC 开启认证服务。
 *
 * AppStorage 键：
 *   isLoggedIn / userUnionId / userNickName / userAvatarUri
 */
import { authentication } from '@kit.AccountKit';
import { util } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import auth from '@hw-agconnect/auth';
import { UserInfo } from '../model/UserInfo';
import { AgcInitializer } from './AgcInitializer';
import { CloudService } from './CloudService';

const DOMAIN: number = 0x0001;
const TAG: string = 'AccountService';

/** AppStorage：是否已登录 */
export const KEY_IS_LOGGED_IN: string = 'isLoggedIn';
/** AppStorage：UnionID */
export const KEY_USER_UNION_ID: string = 'userUnionId';
/** AppStorage：昵称 */
export const KEY_USER_NICK_NAME: string = 'userNickName';
/** AppStorage：头像 URI */
export const KEY_USER_AVATAR_URI: string = 'userAvatarUri';

export class AccountService {
  /** 初始化 AppStorage 登录态默认值，在 EntryAbility 中调用 */
  static initStorage(): void {
    AppStorage.setOrCreate(KEY_IS_LOGGED_IN, false);
    AppStorage.setOrCreate(KEY_USER_UNION_ID, '');
    AppStorage.setOrCreate(KEY_USER_NICK_NAME, '');
    AppStorage.setOrCreate(KEY_USER_AVATAR_URI, '');
  }

  static isLoggedIn(): boolean {
    return AppStorage.get<boolean>(KEY_IS_LOGGED_IN) ?? false;
  }

  static getCurrentUser(): UserInfo | undefined {
    if (!AccountService.isLoggedIn()) {
      return undefined;
    }
    const unionId: string = AppStorage.get<string>(KEY_USER_UNION_ID) ?? '';
    if (unionId.length === 0) {
      return undefined;
    }
    return {
      unionId: unionId,
      openId: '',
      nickName: AppStorage.get<string>(KEY_USER_NICK_NAME) ?? '',
      avatarUri: AppStorage.get<string>(KEY_USER_AVATAR_URI) ?? ''
    };
  }

  /**
   * 华为账号登录 + AGC hwid 认证 + 云 Kit 初始化。
   * @param context UI 上下文
   */
  static async signIn(context: common.Context): Promise<UserInfo> {
    if (!AgcInitializer.isReady()) {
      throw new Error('AGC 未初始化，请先按 docs/AGC_SETUP.md 配置 agconnect-services.json 与 client_id');
    }

    const provider: authentication.HuaweiIDProvider = new authentication.HuaweiIDProvider();
    const loginRequest: authentication.LoginWithHuaweiIDRequest = provider.createLoginWithHuaweiIDRequest();
    loginRequest.forceLogin = true;
    const requestState: string = util.generateRandomUUID();
    loginRequest.state = requestState;

    const controller: authentication.AuthenticationController = new authentication.AuthenticationController(context);
    const loginResponse: authentication.LoginWithHuaweiIDResponse =
      await controller.executeRequest(loginRequest) as authentication.LoginWithHuaweiIDResponse;

    if (loginResponse.state !== undefined && loginResponse.state !== requestState) {
      throw new Error('登录 state 校验失败');
    }

    const credential: authentication.LoginWithHuaweiIDCredential | undefined = loginResponse.data;
    if (credential === undefined || credential.unionID === undefined || credential.unionID.length === 0) {
      throw new Error('未获取到 UnionID');
    }

    let nickName: string = '';
    let avatarUri: string = '';
    try {
      const profile: UserInfo | undefined = await AccountService.fetchProfile(context);
      if (profile !== undefined) {
        nickName = profile.nickName;
        avatarUri = profile.avatarUri;
      }
    } catch (profileErr) {
      hilog.warn(DOMAIN, TAG, 'fetch profile skipped: %{public}s', JSON.stringify(profileErr));
    }

    await auth.signIn({
      autoCreateUser: true,
      credentialInfo: {
        kind: 'hwid'
      }
    });

    CloudService.initCloud();

    const user: UserInfo = {
      unionId: credential.unionID,
      openId: credential.openID ?? '',
      nickName: nickName,
      avatarUri: avatarUri
    };
    AccountService.persistUser(user);
    hilog.info(DOMAIN, TAG, 'signIn success');
    return user;
  }

  /**
   * 获取昵称与头像（需 profile 授权）。
   */
  private static async fetchProfile(context: common.Context): Promise<UserInfo | undefined> {
    const provider: authentication.HuaweiIDProvider = new authentication.HuaweiIDProvider();
    const authRequest: authentication.AuthorizationWithHuaweiIDRequest =
      provider.createAuthorizationWithHuaweiIDRequest();
    authRequest.scopes = ['profile'];
    authRequest.permissions = ['serviceauthcode'];
    authRequest.forceAuthorization = false;
    authRequest.state = util.generateRandomUUID();

    const controller: authentication.AuthenticationController = new authentication.AuthenticationController(context);
    const authResponse: authentication.AuthorizationWithHuaweiIDResponse =
      await controller.executeRequest(authRequest) as authentication.AuthorizationWithHuaweiIDResponse;

    const data = authResponse.data;
    if (data === undefined) {
      return undefined;
    }
    return {
      unionId: '',
      openId: '',
      nickName: data.nickName ?? '',
      avatarUri: data.avatarUri ?? ''
    };
  }

  private static persistUser(user: UserInfo): void {
    AppStorage.setOrCreate(KEY_IS_LOGGED_IN, true);
    AppStorage.setOrCreate(KEY_USER_UNION_ID, user.unionId);
    AppStorage.setOrCreate(KEY_USER_NICK_NAME, user.nickName);
    AppStorage.setOrCreate(KEY_USER_AVATAR_URI, user.avatarUri);
  }

  /**
   * 退出登录：AGC 登出 + 清除本地登录态。
   */
  static async signOut(): Promise<void> {
    try {
      await auth.signOut();
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'auth signOut: %{public}s', JSON.stringify(err));
    }
    AppStorage.setOrCreate(KEY_IS_LOGGED_IN, false);
    AppStorage.setOrCreate(KEY_USER_UNION_ID, '');
    AppStorage.setOrCreate(KEY_USER_NICK_NAME, '');
    AppStorage.setOrCreate(KEY_USER_AVATAR_URI, '');
  }

  /**
   * 将 Account Kit 错误码转为用户可读文案。
   */
  static errorMessage(err: BusinessError): string {
    hilog.error(DOMAIN, TAG, 'code=%{public}d msg=%{public}s', err.code, err.message);
    if (err.code === 1001502001) {
      return '请检查 AGC 是否已配置 SHA-256 证书指纹';
    }
    if (err.code === 1001502012) {
      return '用户取消登录';
    }
    return `登录失败(${err.code})，请检查 client_id 与 AGC 配置`;
  }
}
