import Combine
import Foundation

enum ClockSource: String, Codable {
    case local
    case utcOffset
}

struct ClockSettings: Codable, Equatable {
    var enabled: Bool
    var source: ClockSource
    /// Fixed offset from UTC in seconds. Used only when `source == .utcOffset`.
    var offsetSeconds: Int
    var showDate: Bool
    var showSeconds: Bool
    var showOffset: Bool
}

/// Observable, UserDefaults-backed settings. Every change is persisted
/// immediately; no cloud, no network.
final class Settings: ObservableObject {
    @Published var clock1: ClockSettings { didSet { store(clock1, forKey: "clock1") } }
    @Published var clock2: ClockSettings { didSet { store(clock2, forKey: "clock2") } }
    @Published var epochEnabled: Bool { didSet { defaults.set(epochEnabled, forKey: "epochEnabled") } }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        clock1 = Self.load("clock1", from: defaults) ?? ClockSettings(
            enabled: true, source: .local, offsetSeconds: 0,
            showDate: false, showSeconds: true, showOffset: true)
        clock2 = Self.load("clock2", from: defaults) ?? ClockSettings(
            enabled: false, source: .utcOffset, offsetSeconds: 0,
            showDate: false, showSeconds: true, showOffset: true)
        epochEnabled = defaults.object(forKey: "epochEnabled") as? Bool ?? true
    }

    private func store<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private static func load<T: Decodable>(_ key: String, from defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
