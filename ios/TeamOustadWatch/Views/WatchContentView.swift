import SwiftUI

struct WatchContentView: View {
    @EnvironmentObject var store: WatchDataStore

    var body: some View {
        if store.isDataLoaded {
            TabView {
                WatchHomeView()
                WatchPlanningView()
                WatchQRView()
            }
        } else {
            VStack(spacing: 12) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 32))
                    .foregroundColor(Color(red: 0.91, green: 0.58, blue: 0.28))
                Text("Ouvrez Team\nOustad sur\nvotre iPhone")
                    .multilineTextAlignment(.center)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
    }
}
