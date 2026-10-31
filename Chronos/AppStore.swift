import SwiftUI
import Combine

/// 全局状态：主题 + 世界时钟城市列表，落盘到 UserDefaults。
final class AppStore: ObservableObject {
    @Published var theme: ClockTheme = .aurora
    @Published var cities: [WorldCity] = WorldCity.defaults

    private let themeKey = "chronos.theme"
    private let citiesKey = "chronos.cities"

    init() {
        if let raw = UserDefaults.standard.string(forKey: themeKey),
           let saved = ClockTheme(rawValue: raw) {
            theme = saved
        }
        if let data = UserDefaults.standard.data(forKey: citiesKey),
           let saved = try? JSONDecoder().decode([WorldCity].self, from: data),
           !saved.isEmpty {
            cities = saved
        }
    }

    func cycleTheme() {
        theme = theme.next
        UserDefaults.standard.set(theme.rawValue, forKey: themeKey)
    }

    func add(_ city: WorldCity) {
        guard !cities.contains(where: { $0.identifier == city.identifier }) else { return }
        cities.append(city)
        persistCities()
    }

    func remove(at offsets: IndexSet) {
        cities.remove(atOffsets: offsets)
        persistCities()
    }

    func remove(_ city: WorldCity) {
        cities.removeAll { $0.identifier == city.identifier }
        persistCities()
    }

    func availableCities() -> [WorldCity] {
        let owned = Set(cities.map { $0.identifier })
        return WorldCity.catalog.filter { !owned.contains($0.identifier) }
    }

    private func persistCities() {
        if let data = try? JSONEncoder().encode(cities) {
            UserDefaults.standard.set(data, forKey: citiesKey)
        }
    }
}
