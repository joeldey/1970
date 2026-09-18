import AppKit
import Combine
import SwiftUI

@main
struct App1970: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        // No window UI; the status item (built in AppDelegate) is the app.
        SwiftUI.Settings { EmptyView() }
    }
}

/// Owns the menu-bar status item. Uses AppKit directly because MenuBarExtra
/// does not honor a custom label font, which the tabular-digit requirement
/// needs. Proportional letters + fixed-width digits match the native clock.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = Settings()
    private let popover = NSPopover()
    private var statusItem: NSStatusItem?
    private var timer: Timer?
    private var settingsObserver: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            button.target = self
            button.action = #selector(togglePopover)
        }
        self.statusItem = statusItem

        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PopoverView(settings: settings))

        updateTitle()

        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTitle()
        }
        // .common so the title keeps ticking while the popover/menus are open.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        // Reflect setting changes in the title immediately, not on the next tick.
        settingsObserver = settings.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async { self?.updateTitle() }
        }
    }

    private func updateTitle() {
        statusItem?.button?.title = menuBarString(settings, at: Date())
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
