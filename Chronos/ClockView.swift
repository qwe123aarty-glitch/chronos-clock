import SwiftUI

struct ClockView: View {
    @EnvironmentObject private var store: AppStore
    @State private var now = Date()

    private let ticker = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "时钟", subtitle: localZoneName) {
                Button {
                    withAnimation(.easeInOut(duration: 0.35)) { store.cycleTheme() }
                } label: {
                    HStack(spacing: 7) {
                        Circle()
                            .fill(store.theme.accent)
                            .frame(width: 9, height: 9)
                        Text(store.theme.title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .glassCard(store.theme, radius: 30)
                }
                .buttonStyle(.plain)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    AnalogClockView(theme: store.theme)
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: 330)
                        .padding(.horizontal, 34)
                        .padding(.top, 18)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.35)) { store.cycleTheme() }
                        }

                    digitalReadout

                    Text(Self.dateFormatter.string(from: now))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.40))
                        .monospacedDigit()

                    Spacer(minLength: 24)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .screenBackground(store.theme)
        .onReceive(ticker) { now = $0 }
    }

    // MARK: - 数字读数

    private var digitalReadout: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(Self.hourMinute.string(from: now))
                .font(.system(size: 64, weight: .thin, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(
                    LinearGradient(colors: [.white, .white.opacity(0.72)],
                                   startPoint: .top,
                                   endPoint: .bottom)
                )

            Text(Self.seconds.string(from: now))
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(store.theme.accent)
                .padding(.bottom, 8)
        }
    }

    private var localZoneName: String {
        let name = TimeZone.current.localizedName(for: .generic,
                                                  locale: Locale(identifier: "zh_Hans_CN"))
        return name ?? TimeZone.current.identifier
    }

    // MARK: - 格式化器

    private static let hourMinute: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "HH:mm"
        return f
    }()

    private static let seconds: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "ss"
        return f
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_Hans_CN")
        f.dateFormat = "yyyy年M月d日 EEEE"
        return f
    }()
}
