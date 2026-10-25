import Foundation
import WatchConnectivity
import SwiftUI

/// Single source of truth for all data received from the paired iPhone.
class WatchDataStore: NSObject, ObservableObject, WCSessionDelegate {

    @Published var userName: String = ""
    @Published var memberId: Int = 0
    @Published var subscriptionStatus: String = ""
    @Published var subscriptionName: String = ""
    @Published var gymName: String = ""
    @Published var daysLeft: Int = 0
    @Published var expiresAt: String = ""
    @Published var todayPlanningTitle: String = ""
    @Published var todayExercisesCount: Int = 0
    @Published var qrBase64: String = ""
    @Published var isDataLoaded: Bool = false

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - Update

    func apply(_ message: [String: Any]) {
        DispatchQueue.main.async {
            self.userName = message["userName"] as? String ?? self.userName
            self.memberId = message["memberId"] as? Int ?? self.memberId
            self.subscriptionStatus = message["subscriptionStatus"] as? String ?? self.subscriptionStatus
            self.subscriptionName = message["subscriptionName"] as? String ?? self.subscriptionName
            self.gymName = message["gymName"] as? String ?? self.gymName
            self.daysLeft = message["daysLeft"] as? Int ?? self.daysLeft
            self.expiresAt = message["expiresAt"] as? String ?? self.expiresAt
            self.todayPlanningTitle = message["todayPlanningTitle"] as? String ?? self.todayPlanningTitle
            self.todayExercisesCount = message["todayExercisesCount"] as? Int ?? self.todayExercisesCount
            self.qrBase64 = message["qrBase64"] as? String ?? self.qrBase64
            self.isDataLoaded = !self.userName.isEmpty
        }
    }

    // MARK: - WCSessionDelegate

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        // On activation, request latest data from phone
        if activationState == .activated, session.isReachable {
            session.sendMessage(["request": "sync"], replyHandler: { [weak self] reply in
                self?.apply(reply)
            }, errorHandler: nil)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        apply(message)
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        apply(message)
        replyHandler([:])
    }

    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        apply(applicationContext)
    }

    // Required on iOS SDK; no-op on watchOS (handled by the system).
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif
}
