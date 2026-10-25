import SwiftUI

struct WatchPlanningView: View {
    @EnvironmentObject var store: WatchDataStore

    private let gold = Color(red: 0.91, green: 0.58, blue: 0.28)

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 24))
                .foregroundColor(gold)

            if store.todayPlanningTitle.isEmpty {
                Text("Pas de séance\naujourd'hui")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            } else {
                Text(store.todayPlanningTitle)
                    .font(.system(size: 14, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 10))
                        .foregroundColor(gold)
                    Text("\(store.todayExercisesCount) exercice\(store.todayExercisesCount > 1 ? "s" : "")")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(gold.opacity(0.18))
                .cornerRadius(12)
            }
        }
        .padding()
    }
}
