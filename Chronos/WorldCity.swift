import Foundation

struct WorldCity: Identifiable, Codable, Hashable {
    var name: String
    var identifier: String

    var id: String { identifier }

    var timeZone: TimeZone { TimeZone(identifier: identifier) ?? .current }

    /// 相对本机时区的小时差，可能有半小时（如印度 +2.5）。
    func offsetHours(from date: Date) -> Double {
        let delta = timeZone.secondsFromGMT(for: date) - TimeZone.current.secondsFromGMT(for: date)
        return Double(delta) / 3600.0
    }

    func offsetLabel(from date: Date) -> String {
        let h = offsetHours(from: date)
        if abs(h) < 0.01 { return "与本地相同" }
        let sign = h > 0 ? "+" : "−"
        let v = abs(h)
        let text = v == v.rounded() ? String(format: "%.0f", v) : String(format: "%.1f", v)
        return "\(sign)\(text) 小时"
    }

    func hour(at date: Date) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        return cal.component(.hour, from: date)
    }

    func isDaytime(at date: Date) -> Bool {
        let h = hour(at: date)
        return h >= 6 && h < 18
    }

    func timeText(at date: Date, withSeconds: Bool = false) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let c = cal.dateComponents([.hour, .minute, .second], from: date)
        let h = c.hour ?? 0
        let m = c.minute ?? 0
        let s = c.second ?? 0
        return withSeconds
            ? String(format: "%02d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", h, m)
    }

    /// 该城市此刻是「今天 / 明天 / 昨天」。
    func dayRelation(at date: Date) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let there = cal.dateComponents([.year, .month, .day], from: date)

        var local = Calendar(identifier: .gregorian)
        local.timeZone = .current
        let here = local.dateComponents([.year, .month, .day], from: date)

        guard let a = cal.date(from: there), let b = local.date(from: here) else { return "" }
        let days = Int((a.timeIntervalSince(b) / 86400).rounded())
        switch days {
        case 1: return "明天"
        case -1: return "昨天"
        default: return ""
        }
    }

    static let catalog: [WorldCity] = [
        WorldCity(name: "北京", identifier: "Asia/Shanghai"),
        WorldCity(name: "香港", identifier: "Asia/Hong_Kong"),
        WorldCity(name: "台北", identifier: "Asia/Taipei"),
        WorldCity(name: "东京", identifier: "Asia/Tokyo"),
        WorldCity(name: "首尔", identifier: "Asia/Seoul"),
        WorldCity(name: "新加坡", identifier: "Asia/Singapore"),
        WorldCity(name: "曼谷", identifier: "Asia/Bangkok"),
        WorldCity(name: "孟买", identifier: "Asia/Kolkata"),
        WorldCity(name: "迪拜", identifier: "Asia/Dubai"),
        WorldCity(name: "莫斯科", identifier: "Europe/Moscow"),
        WorldCity(name: "柏林", identifier: "Europe/Berlin"),
        WorldCity(name: "巴黎", identifier: "Europe/Paris"),
        WorldCity(name: "伦敦", identifier: "Europe/London"),
        WorldCity(name: "纽约", identifier: "America/New_York"),
        WorldCity(name: "芝加哥", identifier: "America/Chicago"),
        WorldCity(name: "丹佛", identifier: "America/Denver"),
        WorldCity(name: "洛杉矶", identifier: "America/Los_Angeles"),
        WorldCity(name: "圣保罗", identifier: "America/Sao_Paulo"),
        WorldCity(name: "开罗", identifier: "Africa/Cairo"),
        WorldCity(name: "悉尼", identifier: "Australia/Sydney"),
        WorldCity(name: "奥克兰", identifier: "Pacific/Auckland"),
        WorldCity(name: "檀香山", identifier: "Pacific/Honolulu")
    ]

    static let defaults: [WorldCity] = [
        WorldCity(name: "北京", identifier: "Asia/Shanghai"),
        WorldCity(name: "伦敦", identifier: "Europe/London"),
        WorldCity(name: "纽约", identifier: "America/New_York"),
        WorldCity(name: "东京", identifier: "Asia/Tokyo")
    ]
}
