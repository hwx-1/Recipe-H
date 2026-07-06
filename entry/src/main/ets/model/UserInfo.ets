/**
 * UserInfo - 登录用户模型
 *
 * 作用：描述当前华为账号登录用户的核心信息，供 ProfilePage、情侣绑定等场景使用。
 *      业务主键统一使用 UnionID（跨应用稳定标识）。
 */
export interface UserInfo {
  unionId: string;
  openId: string;
  nickName: string;
  avatarUri: string;
}
