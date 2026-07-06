/**
 * Index - 应用根入口(AppRoot)
 *
 * 作用：作为 @Entry 根页面，按阶段编排启动流程：
 *      SplashPage(启动动效) → AgreementPage(未同意协议时) → MainPage(主界面)。
 *      协议同意状态持久化于 Preferences，版本变更后会重新弹出。
 */
import { common } from '@kit.AbilityKit';
import { SplashPage } from './SplashPage';
import { AgreementPage } from './AgreementPage';
import { MainPage } from './MainPage';
import { PrefsUtil } from '../common/PrefsUtil';
import { PrefKey, AppConst } from '../common/Constants';

/**
 * 启动阶段枚举。
 */
enum AppPhase {
  SPLASH = 0,
  AGREEMENT = 1,
  MAIN = 2
}

@Entry
@Component
struct Index {
  @State private phase: AppPhase = AppPhase.SPLASH;

  aboutToAppear(): void {
    PrefsUtil.init(getContext(this));
  }

  private hasAgreed(): boolean {
    return PrefsUtil.getNumber(PrefKey.AGREED_TERMS_VERSION, 0) >= AppConst.TERMS_VERSION;
  }

  private onSplashFinish(): void {
    this.phase = this.hasAgreed() ? AppPhase.MAIN : AppPhase.AGREEMENT;
  }

  private onAgree(): void {
    PrefsUtil.setNumber(PrefKey.AGREED_TERMS_VERSION, AppConst.TERMS_VERSION);
    this.phase = AppPhase.MAIN;
  }

  private onDisagree(): void {
    const context = getContext(this) as common.UIAbilityContext;
    context.terminateSelf();
  }

  build() {
    Stack() {
      if (this.phase === AppPhase.SPLASH) {
        SplashPage({
          onFinish: () => {
            this.onSplashFinish();
          }
        })
      } else if (this.phase === AppPhase.AGREEMENT) {
        AgreementPage({
          onAgree: () => {
            this.onAgree();
          },
          onDisagree: () => {
            this.onDisagree();
          }
        })
      } else {
        MainPage()
      }
    }
    .width('100%')
    .height('100%')
  }
}
