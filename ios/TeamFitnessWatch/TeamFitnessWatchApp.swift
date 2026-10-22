import SwiftUI

@main
struct TeamFitnessWatchApp: App {
    @StateObject private var store = WatchDataStore()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(store)
        }
    }
}
