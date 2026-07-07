/**
 * PresetPhrases - 系统预设文案(转发/夸赞)
 *
 * 作用：转发到空间、任务完成后夸赞时供用户选择，不可自定义。
 */
export class PresetPhrases {
  static forwardPhrases(): string[] {
    return ['今晚试试这个？', '看起来好好吃', '周末做这个吧', '想和你一起吃这个'];
  }

  static praisePhrases(): string[] {
    return ['辛苦了 ❤️', '太好吃了！', '你也太棒了吧', '爱你哟', '谢谢宝贝'];
  }

  /** 做完菜打卡发布到空间的预设文案 */
  static completePhrases(): string[] {
    return ['做好啦，来吃饭！', '今日大厨上线 ✨', '成功出锅，求夸夸', '一起开动吧'];
  }

  static dailyPactTemplates(): string[] {
    return ['今晚一起洗碗', '本周一起运动 3 次', '每天说一句我爱你', '一起 11 点前睡觉', '周末一起大扫除'];
  }
}
