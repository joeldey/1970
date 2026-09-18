import ServiceManagement

/// Thin wrapper over `SMAppService.mainApp` so the UI reflects the real
/// registration state rather than a stored guess.
enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Launch at Login change failed: \(error.localizedDescription)")
        }
    }
}
