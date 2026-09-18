# 1970 — Product & Implementation Specification

## 1. Product Summary

**1970** is a tiny native macOS menu-bar utility that displays one or two human-readable clocks alongside an optional Unix epoch counter.

The app is intentionally narrow in scope. It is not a world-clock application, timezone converter, scheduler, or general date/time utility.

Primary goals:

- Native macOS implementation
- Minimal UI
- Very low resource usage
- No network access
- No analytics
- No account system
- No third-party dependencies unless absolutely necessary
- No unnecessary settings or abstractions

The app should feel like a small, polished system utility.

---

## 2. Menu-Bar Display

The menu-bar display may contain:

- Clock 1
- Clock 2 (optional)
- Unix epoch time (optional)

At least one of Clock 1, Clock 2, or Epoch must be enabled.

Components are displayed left-to-right in this order:

`Clock 1 | Clock 2 | Epoch`

Use a visually compact separator such as ` | `.

Examples:

```text
2026-09-18 15:42:17 UTC-7 | 22:42:17 UTC | 1789780937
```

```text
15:42 UTC-7 | 1789780937
```

```text
1789780937
```

Use tabular/monospaced digits so the menu-bar width does not visibly wobble as values change.

The menu-bar display updates once per second whenever any enabled component requires seconds-level updates.

---

## 3. Clock Model

There are exactly two clock slots:

- Clock 1
- Clock 2

Clock 1 is enabled by default.

Clock 2 is disabled by default.

Each clock has these settings:

### 3.1 Enabled

Boolean.

### 3.2 Source

Two possible source types:

- **Local**
- **UTC Offset**

#### Local

Uses the macOS system timezone.

It should automatically follow:

- Current macOS timezone
- Daylight-saving-time changes
- System timezone changes

No timezone selector is exposed for Local mode.

#### UTC Offset

Uses a fixed offset from UTC.

This is intentionally **not** a timezone. It has no DST rules and no named timezone semantics.

Store the selected offset as seconds from UTC.

---

## 4. Clock Display Options

Each clock independently supports:

### 4.1 Show Date

Boolean.

When enabled, date format is fixed:

```text
YYYY-MM-DD
```

No locale-specific date formatting.

No user-selectable date format.

### 4.2 Show Seconds

Boolean.

When enabled:

```text
HH:mm:ss
```

When disabled:

```text
HH:mm
```

Time is always 24-hour.

No AM/PM option.

### 4.3 Show Offset Label

Boolean.

For UTC Offset clocks, display the selected offset using the format rules below.

For Local clocks, this option should display the current numeric UTC offset using the same format rules.

Do not display timezone abbreviations such as PDT, EST, CET, etc.

---

## 5. UTC Offset Formatting

Formatting rules:

- Zero offset: `UTC`
- Whole-hour positive offset: `UTC+5`
- Whole-hour negative offset: `UTC-7`
- Partial-hour positive offset: `UTC+5:30`
- Partial-hour negative offset: `UTC-3:30`

Do not use:

- Spaces after `UTC`
- Decimal-hour notation such as `UTC+5.5`
- Zero padding such as `UTC+05:30`
- `UTC+0`

Examples:

```text
UTC
UTC-8
UTC-3:30
UTC+5:30
UTC+5:45
UTC+12:45
UTC+14
```

---

## 6. UTC Offset Picker

Do not present every arbitrary 15-minute increment.

Instead, derive the set of **currently-used real UTC offsets** from the timezone database available through Foundation/macOS.

Suggested approach:

1. Enumerate `TimeZone.knownTimeZoneIdentifiers`
2. Construct each `TimeZone`
3. Call `secondsFromGMT(for: Date())`
4. Deduplicate the resulting offsets
5. Sort ascending
6. Present them in the picker using the formatting rules above

The app is intentionally using the system timezone database only to discover legitimate offsets.

Once selected, persist the offset value itself in seconds.

Do not persist a timezone identifier for UTC Offset clocks.

The offset list may legitimately change when the OS timezone database changes or when active DST rules cause different offsets to exist.

That is acceptable and desirable.

If a previously saved offset is no longer present in the current derived list, continue supporting/displaying the saved value and include it in the picker so the user is not silently migrated.

---

## 7. Unix Epoch Display

Epoch display is optional.

When enabled, show Unix time as whole seconds since:

```text
1970-01-01 00:00:00 UTC
```

Use:

```swift
Int(Date().timeIntervalSince1970)
```

or an equivalent implementation.

Do not provide milliseconds.

Do not provide selectable epoch units.

Unix epoch time is independent of either clock's timezone or UTC offset.

---

## 8. Settings UI

The dropdown/popover opened from the menu-bar item should expose only the settings needed for the current product.

Suggested organization:

```text
Clock 1
  [x] Show Clock
      Source: Local / UTC Offset
      Offset: [picker]          // only when UTC Offset selected
      [x] Show Date
      [x] Show Seconds
      [x] Show Offset

Clock 2
  [ ] Show Clock
      Source: Local / UTC Offset
      Offset: [picker]
      [ ] Show Date
      [x] Show Seconds
      [x] Show Offset

[x] Show Unix Time

----------------
Launch at Login
Quit 1970
```

Exact layout may be adapted to native macOS conventions, but keep it compact.

Avoid a separate Preferences window unless there is a strong implementation or UX reason to add one.

---

## 9. Default Settings

Suggested defaults:

### Clock 1

- Enabled: true
- Source: Local
- Show Date: false
- Show Seconds: true
- Show Offset: true

### Clock 2

- Enabled: false
- Source: UTC Offset
- Offset: UTC
- Show Date: false
- Show Seconds: true
- Show Offset: true

### Epoch

- Enabled: true

A likely initial menu-bar result:

```text
15:42:17 UTC-7 | 1789780937
```

---

## 10. Persistence

Persist settings locally using the simplest appropriate Apple mechanism, likely `UserDefaults` / `@AppStorage`.

No cloud sync.

No iCloud.

No account.

No network persistence.

---

## 11. Launch at Login

Provide a user-controlled **Launch at Login** toggle.

Use current native Apple APIs, preferably `SMAppService`.

Do not implement custom LaunchAgent plist installation unless necessary.

The setting shown in the UI must accurately reflect the actual registration state.

---

## 12. macOS App Behavior

The app should be menu-bar-only.

Requirements:

- No Dock icon during normal operation
- No normal application window on launch
- Menu-bar item is the primary UI
- Quit command is available from the menu
- App should behave like a lightweight macOS utility

Use native Swift / SwiftUI / AppKit APIs as appropriate.

Prefer the simplest native implementation.

---

## 13. Technical Constraints

- Language: Swift
- Platform: macOS
- Native Apple frameworks only unless a dependency is clearly justified
- App Sandbox compatible
- Suitable for eventual Mac App Store distribution
- No network entitlement unless future product requirements explicitly add networking
- No analytics
- No telemetry
- No crash-reporting SDK
- No third-party updater
- No Electron
- No web view UI

Avoid premature architecture.

This is a small utility and should remain small.

---

## 14. Code Quality Guidance

When modifying the project:

- Make the smallest correct change
- Prefer straightforward code over abstractions
- Do not introduce architecture layers without a demonstrated need
- Do not change signing, bundle identifiers, deployment settings, entitlements, or project-level configuration unless explicitly required
- Build after meaningful changes
- Report exactly what changed
- Report how the change was verified
- Flag unrelated issues, but do not fix them without approval

---

## 15. Non-Goals

Do **not** add any of the following unless explicitly requested later:

- Named timezone selector
- City/world-clock database
- DST rule configuration
- AM/PM format
- Custom date formats
- Locale-sensitive formatting
- Millisecond epoch display
- Epoch conversion tools
- Date arithmetic
- Calendar features
- Alarms
- Timers
- Stopwatch
- Multiple clocks beyond Clock 1 and Clock 2
- Themes
- Custom colors
- Font selection
- Cloud sync
- Widgets
- iOS support
- Networking
- Accounts
- Analytics

---

## 16. Product Identity

Name:

# 1970

Working description:

> UTC and Unix time in your menu bar.

The name refers to the Unix epoch beginning at:

```text
1970-01-01 00:00:00 UTC
```

Keep branding minimal, technical, and clean.

---

## 17. Suggested First Milestone

Build the smallest working version that:

1. Runs as a menu-bar-only app
2. Displays Clock 1 using Local time
3. Displays Unix epoch time
4. Updates once per second
5. Uses stable-width/tabular digits
6. Provides a Quit menu item

Do not implement the full settings model before this milestone works.

After that, add settings incrementally:

1. Clock formatting options
2. UTC Offset mode and picker
3. Clock 2
4. Persistence
5. Launch at Login
6. App Store / signing polish
