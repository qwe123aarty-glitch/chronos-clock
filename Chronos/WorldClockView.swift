import SwiftUI

struct WorldClockView: View {
    @EnvironmentObject private var store: AppStore
    @State private var now = Date()
    @State private var picking = false

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "世界时钟", subtitle: "\(store.cities.count) 个城市") {
                Button {
                    picking = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(store.theme.accent)
                        .frame(width: 38, height: 38)
                        .glassCard(store.theme, radius: 19)
                }
                .buttonStyle(.plain)
            }

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(store.cities) { city in
                        CityRow(city: city, now: now, theme: store.theme)
                            .contextMenu {
                                Button(role: .destructive) {
                                    withAnimation { store.remove(city) }
                                } label: {
                                    Label("移除", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
        }
        .screenBackground(store.theme)
        .onReceive(ticker) { now = $0 }
        .sheet(isPresented: $picking) {
            CityPicker(theme: store.theme,
                       options: store.availableCities()) { city in
                withAnimation { store.add(city) }
                picking = false
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - 城市行

private struct CityRow: View {
    let city: WorldCity
    let now: Date
    let theme: ClockTheme

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(city.isDaytime(at: now)
                          ? theme.accent.opacity(0.16)
                          : Color.white.opacity(0.06))
                Image(systemName: city.isDaytime(at: now) ? "sun.max.fill" : "moon.stars.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(city.isDaytime(at: now) ? theme.accent : Color.white.opacity(0.5))
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(city.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    if !city.dayRelation(at: now).isEmpty {
                        Text(city.dayRelation(at: now))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(theme.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(theme.accent.opacity(0.14)))
                    }
                }
                Text(city.offsetLabel(from: now))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.34))
            }

            Spacer(minLength: 8)

            Text(city.timeText(at: now))
                .font(.system(size: 30, weight: .light, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.white.opacity(city.isDaytime(at: now) ? 0.95 : 0.62))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassCard(theme, radius: 20)
    }
}

// MARK: - 添加城市

private struct CityPicker: View {
    let theme: ClockTheme
    let options: [WorldCity]
    let onPick: (WorldCity) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(options) { city in
                    Button {
                        onPick(city)
                    } label: {
                        HStack {
                            Text(city.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(city.offsetLabel(from: Date()))
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("添加城市")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
