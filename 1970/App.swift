import AppKit
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
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private let settings = Settings()
    private let popover = NSPopover()
    private var statusItem: NSStatusItem?
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            button.target = self
            button.action = #selector(togglePopover)
        }
        self.statusItem = statusItem

        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(settings: settings) { [weak self] in self?.popover.performClose(nil) })

        updateTitle()

        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTitle()
        }
        // .common so the title keeps ticking while menus are open.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func updateTitle() {
        // While the popover is open, keep the item width fixed. A settings
        // change can change the title width, which would slide the variable-
        // width status item out from under the popover. Refresh on close.
        guard !popover.isShown else { return }
        statusItem?.button?.title = menuBarString(settings, at: Date())
    }

    func popoverDidClose(_ notification: Notification) {
        updateTitle()
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
