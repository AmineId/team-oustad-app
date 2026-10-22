import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var store: WatchDataStore

    private let gold = Color(red: 0.91, green: 0.58, blue: 0.28)
    private let violet = Color(red: 0.49, green: 0.23, blue: 0.93)

    private var statusColor: Color {
        switch store.subscriptionStatus {
        case "active": return .green
        case "expired": return .red
        default: return .orange
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {

                // Greeting
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bonjour 👋")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    Text(store.userName)
                        .font(.system(size: 15, weight: .bold))
                        .lineLimit(1)
                }

                Divider()

                // Subscription card
                HStack(spacing: 8) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.gymName.isEmpty ? "Team Fitness" : store.gymName)
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                        if store.subscriptionStatus == "active" {
                            Text("\(store.daysLeft) jour\(store.daysLeft > 1 ? "s" : "") restant\(store.daysLeft > 1 ? "s" : "")")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        } else {
                            Text("Abonnement expiré")
                                .font(.system(size: 10))
                                .foregroundColor(.red)
                        }
                    }
                    Spacer()
                }
                .padding(8)
                .background(Color(white: 0.15))
                .cornerRadius(8)

                // Today planning
                if !store.todayPlanningTitle.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(gold)
                            .font(.system(size: 11))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.todayPlanningTitle)
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(2)
                            Text("\(store.todayExercisesCount) exercice\(store.todayExercisesCount > 1 ? "s" : "")")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(8)
                    .background(gold.opacity(0.18))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}
