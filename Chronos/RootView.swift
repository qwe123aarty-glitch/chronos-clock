import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @State private var tab: Tab = .clock

    enum Tab: Hashable {
        case clock, world, stopwatch, timer
    }

    var body: some View {
        TabView(selection: $tab) {
            ClockView()
                .tabItem { Label("时钟", systemImage: "clock") }
                .tag(Tab.clock)

            WorldClockView()
                .tabItem { Label("世界", systemImage: "globe.asia.australia") }
                .tag(Tab.world)

            StopwatchView()
                .tabItem { Label("秒表", systemImage: "stopwatch") }
                .tag(Tab.stopwatch)

            TimerView()
                .tabItem { Label("计时器", systemImage: "timer") }
                .tag(Tab.timer)
        }
        .tint(store.theme.accent)
    }
}

/// 顶部标题栏，四个页面共用。
struct ScreenHeader<Trailing: View>: View {
    let title: String
    let subtitle: String
    let trailing: Trailing

    init(title: String,
         subtitle: String,
         @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.42))
            }
            Spacer(minLength: 12)
            trailing
        }
        .padding(.horizontal, 22)
        .padding(.top, 10)
    }
}
