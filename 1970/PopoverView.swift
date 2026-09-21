import SwiftUI

/// Staged copy of the settings edited in the popover. Applied to the real
/// `Settings` only when the user clicks OK; Cancel discards it.
private struct DraftSettings: Equatable {
    var clock1: ClockSettings
    var clock2: ClockSettings
    var epochEnabled: Bool
    var separator: Separator
    var launchAtLogin: Bool

    init(_ settings: Settings) {
        clock1 = settings.clock1
        clock2 = settings.clock2
        epochEnabled = settings.epochEnabled
        separator = settings.separator
        launchAtLogin = LaunchAtLogin.isEnabled
    }

    var enabledComponentCount: Int {
        (clock1.enabled ? 1 : 0) + (clock2.enabled ? 1 : 0) + (epochEnabled ? 1 : 0)
    }
}

struct PopoverView: View {
    let settings: Settings
    let close: () -> Void

    @State private var draft: DraftSettings
    /// Snapshot of the settings when the panel opened; OK is enabled only
    /// once the draft differs from this.
    @State private var baseline: DraftSettings
    @State private var offsets: [Int]

    /// A fresh PopoverView is constructed on every open (see AppDelegate), so
    /// initial values here are always current.
    init(settings: Settings, close: @escaping () -> Void) {
        self.settings = settings
        self.close = close
        let snapshot = DraftSettings(settings)
        _draft = State(initialValue: snapshot)
        _baseline = State(initialValue: snapshot)
        _offsets = State(initialValue: availableOffsets(
            at: Date(),
            including: snapshot.clock1.offsetSeconds, snapshot.clock2.offsetSeconds))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text("1970")
                    .font(.headline)
                Text("UTC and Unix time in your menu bar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            ClockSection(
                label: "Show Clock 1",
                clock: $draft.clock1,
                offsets: offsets,
                soleEnabledComponent: draft.clock1.enabled && draft.enabledComponentCount == 1)

            ClockSection(
                label: "Show Clock 2",
                clock: $draft.clock2,
                offsets: offsets,
                soleEnabledComponent: draft.clock2.enabled && draft.enabledComponentCount == 1)

            Toggle("Show Unix Time", isOn: $draft.epochEnabled)
                .disabled(draft.epochEnabled && draft.enabledComponentCount == 1)

            // Only meaningful with two or more components to separate.
            if draft.enabledComponentCount >= 2 {
                Picker("Separator", selection: $draft.separator) {
                    ForEach(Separator.allCases, id: \.self) { sep in
                        Text(sep.glyph).tag(sep)
                    }
                }
                .pickerStyle(.radioGroup)
                .horizontalRadioGroupLayout()
            }

            Divider()

            Toggle("Launch at Login", isOn: $draft.launchAtLogin)

            HStack {
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .keyboardShortcut("q")
                Spacer()
                Button("Cancel") { close() }
                    .keyboardShortcut(.cancelAction)
                Button("OK") { apply(); close() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(draft == baseline)
            }
        }
        .padding(14)
        .frame(width: 260)
    }

    private func apply() {
        settings.clock1 = draft.clock1
        settings.clock2 = draft.clock2
        settings.epochEnabled = draft.epochEnabled
        settings.separator = draft.separator
        if draft.launchAtLogin != LaunchAtLogin.isEnabled {
            LaunchAtLogin.setEnabled(draft.launchAtLogin)
        }
    }

}

private struct ClockSection: View {
    /// Full localizable label (e.g. "Show Clock 1") rather than an interpolated
    /// fragment, so it can be translated as a whole phrase.
    let label: LocalizedStringKey
    @Binding var clock: ClockSettings
    let offsets: [Int]
    let soleEnabledComponent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(label, isOn: $clock.enabled)
                .disabled(soleEnabledComponent)
                .font(.headline)

            if clock.enabled {
                VStack(alignment: .leading, spacing: 6) {
                    Picker("Source", selection: $clock.source) {
                        Text("Local").tag(ClockSource.local)
                        Text("UTC Offset").tag(ClockSource.utcOffset)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()

                    if clock.source == .utcOffset {
                        Picker("Offset", selection: $clock.offsetSeconds) {
                            ForEach(offsets, id: \.self) { seconds in
                                Text(formatOffset(seconds: seconds)).tag(seconds)
                            }
                        }
                        .labelsHidden()
                    }

                    Toggle("Show Date", isOn: $clock.showDate)
                    Toggle("Show Seconds", isOn: $clock.showSeconds)
                    Toggle("Show Offset", isOn: $clock.showOffset)
                }
                .padding(.leading, 12)
            }
        }
    }
}
