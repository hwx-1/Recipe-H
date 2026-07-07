/**
 * Constants - 全局常量
 *
 * 作用：集中管理路由名、Preferences 键、时长等常量，避免魔法字符串散落各处。
 */

/**
 * Navigation 路由页面名称(与 MainPage 中的 NavDestination 一一对应)。
 */
export class RouteName {
  static readonly RECIPE_LIST: string = 'RecipeListPage';
  static readonly RECIPE_DETAIL: string = 'RecipeDetailPage';
  static readonly RANK: string = 'RankPage';
  static readonly TASK_DETAIL: string = 'TaskDetailPage';
  static readonly BIND: string = 'BindPage';
  static readonly FAVORITES: string = 'FavoritesPage';
  static readonly LIKES: string = 'LikesPage';
  static readonly SETTINGS: string = 'SettingsPage';
  static readonly LEGAL: string = 'LegalDocPage';
  static readonly LOGIN: string = 'LoginPage';
  static readonly COOK_COMPLETE: string = 'CookCompletePage';
  static readonly TASK_PUBLISH: string = 'TaskPublishPage';
  static readonly SPACE_FEED: string = 'SpaceFeedListPage';
}

/**
 * Preferences 持久化相关键名。
 */
export class PrefKey {
  static readonly STORE: string = 'app_prefs';
  static readonly AGREED_TERMS_VERSION: string = 'agreed_terms_version';
  static readonly SOUND_ENABLED: string = 'interaction_sound_enabled';
  static readonly COOK_REMINDER_ENABLED: string = 'cook_reminder_enabled';
  static readonly FAVORITE_IDS: string = 'favorite_recipe_ids';
  static readonly LIKE_IDS: string = 'liked_recipe_ids';
  static readonly RECIPE_STATS: string = 'recipe_stats_map';
  static readonly SPACE_DATA: string = 'space_data_json';
  static readonly COOKING_SESSIONS: string = 'cooking_sessions_json';
  static readonly COOKING_COMPLETED_COUNT: string = 'cooking_completed_count';
}

/** AppStorage：MainPage 切换 Tab（HomePage 烹饪横幅等使用） */
export const KEY_SWITCH_TAB: string = 'switchToTab';

/**
 * 业务时长/阈值常量。
 */
export class AppConst {
  /** 当前用户协议版本，协议变更时递增以触发重新同意 */
  static readonly TERMS_VERSION: number = 1;
  /** 启动页停留时长(ms) */
  static readonly SPLASH_DURATION: number = 3000;
  /** 邀请码有效期(天) */
  static readonly INVITE_CODE_VALID_DAYS: number = 7;
  /** 烹饪超时下限(分钟) */
  static readonly COOK_MIN_MINUTES: number = 45;
  /** 烹饪超时相对预估的倍数 */
  static readonly COOK_TIME_FACTOR: number = 1.5;
}
