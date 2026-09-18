import SwiftUI

struct PopoverView: View {
    @ObservedObject var settings: Settings

    @State private var offsets: [Int] = []
    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ClockSection(
                title: "Clock 1",
                clock: $settings.clock1,
                offsets: offsets,
                soleEnabledComponent: isSole(\.clock1.enabled))

            ClockSection(
                title: "Clock 2",
                clock: $settings.clock2,
                offsets: offsets,
                soleEnabledComponent: isSole(\.clock2.enabled))

            Toggle("Show Unix Time", isOn: $settings.epochEnabled)
                .disabled(settings.epochEnabled && settings.enabledComponentCount == 1)

            Divider()

            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    LaunchAtLogin.setEnabled(newValue)
                    launchAtLogin = LaunchAtLogin.isEnabled
                }

            Button("Quit 1970") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(14)
        .frame(width: 260)
        .onAppear(perform: refreshOffsets)
    }

    /// True when `keyPath` is currently the only enabled component, so its
    /// toggle should be locked on (at least one must stay enabled).
    private func isSole(_ keyPath: KeyPath<Settings, Bool>) -> Bool {
        settings[keyPath: keyPath] && settings.enabledComponentCount == 1
    }

    private func refreshOffsets() {
        offsets = availableOffsets(
            at: Date(),
            including: settings.clock1.offsetSeconds, settings.clock2.offsetSeconds)
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

                    if clock.source == .utcOffset {
                        Picker("Offset", selection: $clock.offsetSeconds) {
                            ForEach(offsets, id: \.self) { seconds in
                                Text(formatOffset(seconds: seconds)).tag(seconds)
                            }
                        }
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
