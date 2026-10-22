import Foundation
import WatchConnectivity

/// Manages WatchConnectivity session for syncing member data to Apple Watch.
class WatchConnectivityService: NSObject, WCSessionDelegate {

    static let shared = WatchConnectivityService()
    private(set) var lastData: [String: Any] = [:]

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func sendMemberData(_ data: [String: Any]) {
        lastData = data
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated else { return }

        // updateApplicationContext stores latest data so the watch gets it on next wake
        try? WCSession.default.updateApplicationContext(data)

        // Also push immediately if watch is reachable
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(data, replyHandler: nil, errorHandler: nil)
        }
    }

    // MARK: - WCSessionDelegate

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        // Reply with the latest cached data when watch requests it
        replyHandler(lastData)
    }
}
