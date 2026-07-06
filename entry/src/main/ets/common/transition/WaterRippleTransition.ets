/**
 * WaterRippleTransition - 全局水波转场
 *
 * 作用：为所有 Navigation 子页面(NavDestination)提供统一的“水波涟漪”出入场效果——
 *      进场时从中心缩放放大 + 透明度渐显，形成柔和的涟漪扩散观感；出场逆向收拢。
 * 说明：采用组件级 TransitionEffect(稳定、无需按栈索引注册)，各页面根节点调用
 *      rippleTransition() 绑定到 .transition() 即可。
 * 用法：
 *   NavDestination() { ... }.transition(rippleTransition())
 */

/**
 * 统一的水波涟漪转场效果。
 * 缩放中心默认在组件中心，配合透明度形成涟漪扩散感。
 */
export function rippleTransition(): TransitionEffect {
  return TransitionEffect
    .scale({ x: 0.85, y: 0.85, centerX: '50%', centerY: '50%' })
    .combine(TransitionEffect.opacity(0))
    .animation({ duration: 380, curve: Curve.EaseInOut });
}
