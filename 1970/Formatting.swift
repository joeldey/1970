import Foundation

/// Formats a UTC offset in seconds per the spec's rules.
/// 0 -> "UTC", whole hours -> "UTC+5"/"UTC-7", partial -> "UTC+5:30".
/// No spaces, no decimal notation, no hour zero-padding, never "UTC+0".
func formatOffset(seconds: Int) -> String {
    if seconds == 0 { return "UTC" }
    let sign = seconds > 0 ? "+" : "-"
    let magnitude = abs(seconds)
    let hours = magnitude / 3600
    let minutes = (magnitude % 3600) / 60
    if minutes == 0 {
        return "UTC\(sign)\(hours)"
    }
    return String(format: "UTC%@%d:%02d", sign, hours, minutes)
}

/// Reused POSIX formatter so digits/format never pick up user locale.
private let clockFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
}()

/// Formats a single clock's string, e.g. "2026-09-18 15:42:17 UTC-7".
func formatClock(_ clock: ClockSettings, at date: Date) -> String {
    let timeZone: TimeZone
    let offsetSeconds: Int
    switch clock.source {
    case .local:
        timeZone = .current
        offsetSeconds = timeZone.secondsFromGMT(for: date)
    case .utcOffset:
        timeZone = TimeZone(secondsFromGMT: clock.offsetSeconds) ?? .gmt
        offsetSeconds = clock.offsetSeconds
    }

    var pattern = ""
    if clock.showDate { pattern += "yyyy-MM-dd " }
    pattern += clock.showSeconds ? "HH:mm:ss" : "HH:mm"

    clockFormatter.timeZone = timeZone
    clockFormatter.dateFormat = pattern
    var result = clockFormatter.string(from: date)

    if clock.showOffset {
        result += " " + formatOffset(seconds: offsetSeconds)
    }
    return result
}

/// Builds the full menu-bar string: enabled components joined by " | ".
func menuBarString(_ settings: Settings, at date: Date) -> String {
    var parts: [String] = []
    if settings.clock1.enabled { parts.append(formatClock(settings.clock1, at: date)) }
    if settings.clock2.enabled { parts.append(formatClock(settings.clock2, at: date)) }
    if settings.epochEnabled { parts.append(String(Int(date.timeIntervalSince1970))) }
    return parts.joined(separator: " | ")
}

/// Distinct real UTC offsets (in seconds) currently in use across the system
/// timezone database, sorted ascending. `include` guarantees a saved offset
/// remains selectable even if no zone currently reports it.
func availableOffsets(at date: Date, including extra: Int...) -> [Int] {
    var offsets = Set(extra)
    for id in TimeZone.knownTimeZoneIdentifiers {
        if let tz = TimeZone(identifier: id) {
            offsets.insert(tz.secondsFromGMT(for: date))
        }
    }
    return offsets.sorted()
}
