import SwiftUI
import UIKit

struct StopwatchView: View {
    @EnvironmentObject private var store: AppStore

    @State private var running = false
    @State private var startDate: Date?
    @State private var accumulated: TimeInterval = 0
    @State private var laps: [TimeInterval] = []

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "秒表", subtitle: "精确到百分之一秒") { EmptyView() }

            display
                .padding(.top, 26)

            controls
                .padding(.horizontal, 34)
                .padding(.top, 26)

            lapList
        }
        .screenBackground(store.theme)
    }

    // MARK: - 读数

    private var display: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !running)) { context in
            VStack(spacing: 8) {
                Text(Self.format(elapsed(at: context.date)))
                    .font(.system(size: 62, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(
                        LinearGradient(colors: [.white, Color.white.opacity(0.70)],
                                       startPoint: .top,
                                       endPoint: .bottom)
                    )
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text(laps.isEmpty ? "就绪" : "第 \(laps.count) 圈")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 按钮

    private var controls: some View {
        HStack(spacing: 16) {
            Button {
                running ? lap() : reset()
            } label: {
                Text(running ? "计次" : "复位")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(canReset ? 0.85 : 0.25))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .glassCard(store.theme, radius: 27)
            }
            .buttonStyle(.plain)
            .disabled(!canReset)

            Button {
                running ? stop() : start()
            } label: {
                Text(running ? "停止" : "启动")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        Capsule().fill(running ? Color.white.opacity(0.92) : store.theme.accent)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 圈速

    private var lapList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(Array(laps.indices).reversed(), id: \.self) { index in
                    LapRow(index: index,
                           split: laps[index] - (index == 0 ? 0 : laps[index - 1]),
                           total: laps[index])
                    Divider().overlay(Color.white.opacity(0.06))
                }
            }
            .padding(.top, 10)
        }
        .padding(.top, 18)
    }

    // MARK: - 逻辑

    private var canReset: Bool {
        running || accumulated > 0 || !laps.isEmpty
    }

    private func elapsed(at date: Date) -> TimeInterval {
        guard running, let start = startDate else { return accumulated }
        return accumulated + date.timeIntervalSince(start)
    }

    private func start() {
        startDate = Date()
        running = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func stop() {
        accumulated = elapsed(at: Date())
        startDate = nil
        running = false
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func lap() {
        laps.append(elapsed(at: Date()))
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func reset() {
        running = false
        startDate = nil
        accumulated = 0
        laps.removeAll()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func format(_ value: TimeInterval) -> String {
        let t = max(0, value)
        let minutes = Int(t) / 60
        let seconds = Int(t) % 60
        let hundredths = Int((t - floor(t)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, hundredths)
    }
}

private struct LapRow: View {
    let index: Int
    let split: TimeInterval
    let total: TimeInterval

    var body: some View {
        HStack {
            Text(String(format: "%02d", index + 1))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
                .frame(width: 30, alignment: .leading)

            Text(StopwatchView.format(split))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.88))

            Spacer()

            Text(StopwatchView.format(total))
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.38))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 13)
    }
}
