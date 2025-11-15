import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var blurEffectView: UIVisualEffectView?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Detect screenshot attempts
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(screenshotTaken),
      name: UIApplication.userDidTakeScreenshotNotification,
      object: nil
    )
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Called when user takes a screenshot
  @objc private func screenshotTaken() {
    // Screenshot was taken - log this event if needed
    print("⚠️ Screenshot detected")
  }
  
  // Hide content when app enters background (prevents preview in app switcher)
  override func applicationWillResignActive(_ application: UIApplication) {
    addBlurEffect()
  }
  
  // Show content when app becomes active again
  override func applicationDidBecomeActive(_ application: UIApplication) {
    removeBlurEffect()
  }
  
  private func addBlurEffect() {
    guard let window = self.window else { return }
    
    if blurEffectView == nil {
      let blurEffect = UIBlurEffect(style: .dark)
      let blurView = UIVisualEffectView(effect: blurEffect)
      blurView.frame = window.bounds
      blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      blurView.tag = 999 // Tag for easy identification
      window.addSubview(blurView)
      blurEffectView = blurView
    }
  }
  
  private func removeBlurEffect() {
    blurEffectView?.removeFromSuperview()
    blurEffectView = nil
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}
