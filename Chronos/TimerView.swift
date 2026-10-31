import SwiftUI
import UIKit
import UserNotifications

struct TimerView: View {
    @EnvironmentObject private var store: AppStore

    @State private var total: TimeInterval = 5 * 60
    @State private var remaining: TimeInterval = 5 * 60
    @State private var endDate: Date?
    @State private var running = false
    @State private var finished = false

    private let ticker = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    private static let presets: [Int] = [1, 3, 5, 10, 15, 25, 30, 45, 60]

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "计时器", subtitle: running ? "倒计时中" : "选择一个时长") { EmptyView() }

            ring
                .padding(.top, 22)

            timeButtons
                .padding(.horizontal, 24)
                .padding(.top, 8)

            presetRow
                .padding(.top, 20)

            Spacer(minLength: 16)

            actionButton
                .padding(.horizontal, 34)
                .padding(.bottom, 24)
        }
        .screenBackground(store.theme)
        .onReceive(ticker) { _ in tick() }
        .onAppear { NotificationHelper.requestAuthorization() }
    }

    // MARK: - 圆环

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.07), lineWidth: 10)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [store.theme.accent, store.theme.secondary, store.theme.accent],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: progress)

            VStack(spacing: 10) {
                Text(Self.clockText(remaining))
                    .font(.system(size: 54, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(
                        LinearGradient(colors: [.white, Color.white.opacity(0.72)],
                                       startPoint: .top,
                                       endPoint: .bottom)
                    )
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text(finished ? "时间到" : (running ? "剩余" : "总计 \(Self.minutesLabel(total))"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(finished ? store.theme.accent : Color.white.opacity(0.35))
            }
            .padding(.horizontal, 40)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 280)
        .padding(.horizontal, 40)
    }

    // MARK: - 加减

    private var timeButtons: some View {
        HStack(spacing: 14) {
            adjustButton(symbol: "minus", amount: -60)
            adjustButton(symbol: "plus", amount: 60)
        }
        .opacity(running ? 0.3 : 1)
        .disabled(running)
    }

    private func adjustButton(symbol: String, amount: TimeInterval) -> some View {
        Button {
            let next = max(60, min(99 * 60, total + amount))
            total = next
            remaining = next
            finished = false
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .bold))
                Text("1 分钟")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.75))
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .glassCard(store.theme, radius: 20)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 预设

    private var presetRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(Self.presets, id: \.self) { minutes in
                    Button {
                        select(minutes: minutes)
                    } label: {
                        Text("\(minutes)")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(isSelected(minutes)
                                             ? Color.black.opacity(0.85)
                                             : Color.white.opacity(0.55))
                            .frame(width: 46, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(isSelected(minutes)
                                          ? store.theme.accent
                                          : Color.white.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 22)
        }
        .opacity(running ? 0.3 : 1)
        .disabled(running)
    }

    // MARK: - 主按钮

    private var actionButton: some View {
        Button {
            if running {
                pause()
            } else if finished {
                resetAll()
            } else {
                start()
            }
        } label: {
            Text(running ? "暂停" : (finished ? "重新开始" : "开始"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.85))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    Capsule().fill(store.theme.accent)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 逻辑

    private var progress: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(max(0, min(1, remaining / total)))
    }

    private func isSelected(_ minutes: Int) -> Bool {
        Int(total / 60) == minutes && !running
    }

    private func select(minutes: Int) {
        total = TimeInterval(minutes * 60)
        remaining = total
        finished = false
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func start() {
        if remaining <= 0 { remaining = total }
        endDate = Date().addingTimeInterval(remaining)
        running = true
        finished = false
        NotificationHelper.schedule(after: remaining)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func pause() {
        if let end = endDate {
            remaining = max(0, end.timeIntervalSinceNow)
        }
        running = false
        endDate = nil
        NotificationHelper.cancel()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func resetAll() {
        running = false
        endDate = nil
        remaining = total
        finished = false
        NotificationHelper.cancel()
    }

    private func tick() {
        guard running, let end = endDate else { return }
        let left = end.timeIntervalSinceNow
        if left <= 0 {
            remaining = 0
            running = false
            endDate = nil
            finished = true
            NotificationHelper.cancel()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            remaining = left
        }
    }

    // MARK: - 格式化

    static func clockText(_ value: TimeInterval) -> String {
        let t = max(0, value.rounded(.up))
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%02d:%02d", m, s)
    }

    static func minutesLabel(_ value: TimeInterval) -> String {
        let m = Int(value / 60)
        return m >= 60 ? "\(m / 60) 小时 \(m % 60) 分" : "\(m) 分钟"
    }
}

// MARK: - 本地通知

enum NotificationHelper {
    private static let id = "chronos.timer.finished"

    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func schedule(after seconds: TimeInterval) {
        cancel()
        let content = UNMutableNotificationContent()
        content.title = "计时结束"
        content.body = "你设定的倒计时已经走完。"
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    static func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [id])
    }
}
