import SwiftUI

/// 三套配色，点按表盘即可切换。
enum ClockTheme: String, CaseIterable, Identifiable {
    case aurora
    case ember
    case mono

    var id: String { rawValue }

    var title: String {
        switch self {
        case .aurora: return "极光"
        case .ember:  return "熔岩"
        case .mono:   return "墨白"
        }
    }

    var accent: Color {
        switch self {
        case .aurora: return Color(red: 0.36, green: 0.86, blue: 0.96)
        case .ember:  return Color(red: 1.00, green: 0.56, blue: 0.30)
        case .mono:   return Color(red: 0.93, green: 0.93, blue: 0.96)
        }
    }

    var secondary: Color {
        switch self {
        case .aurora: return Color(red: 0.56, green: 0.45, blue: 1.00)
        case .ember:  return Color(red: 0.96, green: 0.28, blue: 0.42)
        case .mono:   return Color(red: 0.56, green: 0.59, blue: 0.66)
        }
    }

    /// 背景从深到更深，两段渐变。
    var background: [Color] {
        switch self {
        case .aurora:
            return [Color(red: 0.027, green: 0.055, blue: 0.110),
                    Color(red: 0.043, green: 0.110, blue: 0.180)]
        case .ember:
            return [Color(red: 0.098, green: 0.039, blue: 0.031),
                    Color(red: 0.176, green: 0.063, blue: 0.055)]
        case .mono:
            return [Color(red: 0.043, green: 0.043, blue: 0.051),
                    Color(red: 0.098, green: 0.098, blue: 0.118)]
        }
    }

    /// 卡片底色，半透明叠加在渐变之上。
    var card: Color { Color.white.opacity(0.055) }
    var hairline: Color { Color.white.opacity(0.10) }

    var next: ClockTheme {
        let all = ClockTheme.allCases
        let i = all.firstIndex(of: self) ?? 0
        return all[(i + 1) % all.count]
    }
}

/// 全屏背景：竖向渐变 + 顶部一团主题色辉光。
struct ScreenBackground: ViewModifier {
    let theme: ClockTheme

    func body(content: Content) -> some View {
        ZStack {
            LinearGradient(colors: theme.background,
                           startPoint: .top,
                           endPoint: .bottom)
                .ignoresSafeArea()

            RadialGradient(colors: [theme.accent.opacity(0.18), .clear],
                           center: UnitPoint(x: 0.5, y: 0.12),
                           startRadius: 8,
                           endRadius: 460)
                .blendMode(.screen)
                .ignoresSafeArea()

            content
        }
    }
}

extension View {
    func screenBackground(_ theme: ClockTheme) -> some View {
        modifier(ScreenBackground(theme: theme))
    }
}

/// 玻璃质感卡片。
struct GlassCard: ViewModifier {
    let theme: ClockTheme
    var radius: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(theme.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func glassCard(_ theme: ClockTheme, radius: CGFloat = 22) -> some View {
        modifier(GlassCard(theme: theme, radius: radius))
    }
}
