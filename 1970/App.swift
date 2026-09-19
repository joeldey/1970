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

        updateTitle()

        // Fire on whole-second boundaries so the display flips in step with
        // the native menu-bar clock.
        let nextSecond = Date(timeIntervalSince1970: Date().timeIntervalSince1970.rounded(.down) + 1)
        let timer = Timer(fire: nextSecond, interval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTitle()
        }
        timer.tolerance = 0.05
        // .common so the title keeps ticking while menus are open.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func updateTitle() {
        guard let button = statusItem?.button else { return }
        let title = menuBarString(settings, at: Date())
        if button.title != title { button.title = title }
    }

    func popoverDidClose(_ notification: Notification) {
        // Reflect just-applied settings immediately rather than on the next tick.
        updateTitle()
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            // The title keeps ticking while the panel is open; its width stays
            // constant (monospaced digits, and settings only change on OK,
            // which closes the panel), so the popover's anchor cannot drift.
            // Rebuild the content each time so the panel's staged-edit state
            // starts fresh from the saved settings (a prior Cancel is discarded).
            popover.contentViewController = NSHostingController(
                rootView: PopoverView(settings: settings) { [weak self] in self?.popover.performClose(nil) })
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
