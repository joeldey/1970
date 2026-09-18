import Combine
import SwiftUI

/// Publishes the current time once per second on the main run loop.
final class Ticker: ObservableObject {
    @Published private(set) var now = Date()
    private var timer: Timer?

    init() {
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.now = Date()
        }
        // .common so the menu bar keeps updating while a menu/popover is open.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    deinit { timer?.invalidate() }
}

@main
struct App1970: App {
    @StateObject private var settings = Settings()
    @StateObject private var ticker = Ticker()

    var body: some Scene {
        MenuBarExtra {
            PopoverView(settings: settings)
        } label: {
            Text(menuBarString(settings, at: ticker.now))
                .monospacedDigit()
        }
        .menuBarExtraStyle(.window)
    }
}
