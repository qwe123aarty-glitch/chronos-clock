import SwiftUI

/// 逐帧重绘的机械表盘。秒针连续扫动，不是一秒一跳。
struct AnalogClockView: View {
    let theme: ClockTheme
    var showsNumerals: Bool = true

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2
                let dialRect = CGRect(x: center.x - radius,
                                      y: center.y - radius,
                                      width: radius * 2,
                                      height: radius * 2)

                let cal = Calendar.current
                let c = cal.dateComponents([.hour, .minute, .second, .nanosecond], from: context.date)
                let sec = Double(c.second ?? 0) + Double(c.nanosecond ?? 0) / 1_000_000_000
                let minute = Double(c.minute ?? 0) + sec / 60.0
                let hour = Double((c.hour ?? 0) % 12) + minute / 60.0

                // ── 盘面底色 ──────────────────────────────
                ctx.fill(Path(ellipseIn: dialRect),
                         with: .radialGradient(
                            Gradient(colors: [
                                Color.white.opacity(0.10),
                                Color.white.opacity(0.025),
                                Color.black.opacity(0.28)
                            ]),
                            center: center,
                            startRadius: 0,
                            endRadius: radius))

                // ── 外圈 ────────────────────────────────
                ctx.stroke(Path(ellipseIn: dialRect.insetBy(dx: 0.75, dy: 0.75)),
                           with: .linearGradient(
                            Gradient(colors: [
                                theme.accent.opacity(0.85),
                                theme.secondary.opacity(0.30),
                                theme.accent.opacity(0.55)
                            ]),
                            startPoint: CGPoint(x: dialRect.minX, y: dialRect.minY),
                            endPoint: CGPoint(x: dialRect.maxX, y: dialRect.maxY)),
                           lineWidth: 1.5)

                // ── 刻度 ────────────────────────────────
                let tickOuter = radius - 13
                for i in 0..<60 {
                    let major = i % 5 == 0
                    let a = Double(i) / 60.0 * 2 * Double.pi
                    let inner = tickOuter - (major ? 15 : 6)
                    var p = Path()
                    p.move(to: CGPoint(x: center.x + sin(a) * inner, y: center.y - cos(a) * inner))
                    p.addLine(to: CGPoint(x: center.x + sin(a) * tickOuter, y: center.y - cos(a) * tickOuter))
                    ctx.stroke(p,
                               with: .color(.white.opacity(major ? 0.55 : 0.14)),
                               lineWidth: major ? 2.0 : 1.0)
                }

                // ── 数字 ────────────────────────────────
                if showsNumerals {
                    let r = radius * 0.735
                    for h in 1...12 {
                        let a = Double(h) / 12.0 * 2 * Double.pi
                        let pt = CGPoint(x: center.x + sin(a) * r, y: center.y - cos(a) * r)
                        let label = Text("\(h)")
                            .font(.system(size: radius * 0.098,
                                          weight: h % 3 == 0 ? .semibold : .regular,
                                          design: .rounded))
                            .foregroundColor(.white.opacity(h % 3 == 0 ? 0.92 : 0.38))
                        ctx.draw(label, at: pt, anchor: .center)
                    }
                }

                // 指针路径：默认竖直向上，再绕盘心旋转。
                func hand(angle: Double,
                          length: CGFloat,
                          width: CGFloat,
                          tail: CGFloat) -> Path {
                    let rect = CGRect(x: -width / 2,
                                      y: -length,
                                      width: width,
                                      height: length + tail)
                    let base = Path(roundedRect: rect, cornerRadius: width / 2)
                    let t = CGAffineTransform(translationX: center.x, y: center.y)
                        .rotated(by: CGFloat(angle))
                    return base.applying(t)
                }

                // ── 时针 ────────────────────────────────
                ctx.fill(hand(angle: hour / 12 * 2 * Double.pi,
                              length: radius * 0.44,
                              width: radius * 0.058,
                              tail: radius * 0.07),
                         with: .color(.white.opacity(0.93)))

                // ── 分针 ────────────────────────────────
                ctx.fill(hand(angle: minute / 60 * 2 * Double.pi,
                              length: radius * 0.64,
                              width: radius * 0.038,
                              tail: radius * 0.09),
                         with: .color(.white.opacity(0.93)))

                // ── 秒针（带辉光）────────────────────────
                let secondAngle = sec / 60 * 2 * Double.pi
                ctx.drawLayer { layer in
                    layer.addFilter(.blur(radius: 9))
                    layer.fill(hand(angle: secondAngle,
                                    length: radius * 0.76,
                                    width: radius * 0.030,
                                    tail: radius * 0.13),
                               with: .color(theme.accent.opacity(0.65)))
                }
                ctx.fill(hand(angle: secondAngle,
                              length: radius * 0.76,
                              width: radius * 0.017,
                              tail: radius * 0.13),
                         with: .color(theme.accent))

                // ── 中心轴 ──────────────────────────────
                let capR = radius * 0.036
                ctx.fill(Path(ellipseIn: CGRect(x: center.x - capR,
                                                y: center.y - capR,
                                                width: capR * 2,
                                                height: capR * 2)),
                         with: .color(theme.accent))
                let dotR = radius * 0.013
                ctx.fill(Path(ellipseIn: CGRect(x: center.x - dotR,
                                                y: center.y - dotR,
                                                width: dotR * 2,
                                                height: dotR * 2)),
                         with: .color(Color(white: 0.05)))
            }
        }
        .accessibilityLabel("指针时钟")
    }
}
