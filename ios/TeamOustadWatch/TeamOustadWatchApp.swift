import SwiftUI

@main
struct TeamOustadWatchApp: App {
    @StateObject private var store = WatchDataStore()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(store)
        }
    }
}
