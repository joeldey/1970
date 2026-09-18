import SwiftUI

/// Staged copy of the settings edited in the popover. Applied to the real
/// `Settings` only when the user clicks OK; Cancel discards it.
private struct DraftSettings: Equatable {
    var clock1: ClockSettings
    var clock2: ClockSettings
    var epochEnabled: Bool
    var launchAtLogin: Bool

    init(_ settings: Settings) {
        clock1 = settings.clock1
        clock2 = settings.clock2
        epochEnabled = settings.epochEnabled
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
    @State private var offsets: [Int] = []

    init(settings: Settings, close: @escaping () -> Void) {
        self.settings = settings
        self.close = close
        let snapshot = DraftSettings(settings)
        _draft = State(initialValue: snapshot)
        _baseline = State(initialValue: snapshot)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text("1970")
                    .font(.headline)
                Text("UTC and Unix time in your menu bar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            ClockSection(
                title: "Clock 1",
                clock: $draft.clock1,
                offsets: offsets,
                soleEnabledComponent: draft.clock1.enabled && draft.enabledComponentCount == 1)

            ClockSection(
                title: "Clock 2",
                clock: $draft.clock2,
                offsets: offsets,
                soleEnabledComponent: draft.clock2.enabled && draft.enabledComponentCount == 1)

            Toggle("Show Unix Time", isOn: $draft.epochEnabled)
                .disabled(draft.epochEnabled && draft.enabledComponentCount == 1)

            Divider()

            Toggle("Launch at Login", isOn: $draft.launchAtLogin)

            HStack {
                Button("Quit") { NSApplication.shared.terminate(nil) }
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
        .onAppear {
            // Re-sync from the source of truth each time the panel opens, so a
            // prior Cancel is fully discarded and OK starts disabled again.
            let snapshot = DraftSettings(settings)
            draft = snapshot
            baseline = snapshot
            refreshOffsets()
        }
    }

    private func apply() {
        settings.clock1 = draft.clock1
        settings.clock2 = draft.clock2
        settings.epochEnabled = draft.epochEnabled
        if draft.launchAtLogin != LaunchAtLogin.isEnabled {
            LaunchAtLogin.setEnabled(draft.launchAtLogin)
        }
    }

    private func refreshOffsets() {
        offsets = availableOffsets(
            at: Date(),
            including: draft.clock1.offsetSeconds, draft.clock2.offsetSeconds)
    }
}

private struct ClockSection: View {
    let title: String
    @Binding var clock: ClockSettings
    let offsets: [Int]
    let soleEnabledComponent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Show \(title)", isOn: $clock.enabled)
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
