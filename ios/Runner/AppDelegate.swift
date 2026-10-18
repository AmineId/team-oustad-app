import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Bloquer les screenshots et l'enregistrement d'écran
    disableScreenCapture()

    // Channel utilitaire iOS
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "team.fitness.security",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "checkFirebasePlistBundle":
          // Vérifie que le bundle ID de GoogleService-Info.plist correspond
          // au bundle ID actuel (peut différer après re-signature xtool)
          if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
             let plist = NSDictionary(contentsOfFile: path),
             let plistBundleId = plist["BUNDLE_ID"] as? String {
            result(plistBundleId == Bundle.main.bundleIdentifier)
          } else {
            result(false)
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Désactive la capture d'écran en masquant le contenu dans le task switcher
  private func disableScreenCapture() {
    if let window = self.window {
      // Ajouter un observer pour détecter les screenshots
      NotificationCenter.default.addObserver(
        forName: UIApplication.userDidTakeScreenshotNotification,
        object: nil,
        queue: .main
      ) { _ in
        // Log ou action quand un screenshot est détecté
        print("⚠️ Screenshot détecté!")
      }
      
      // Masquer le contenu dans le task switcher
      NotificationCenter.default.addObserver(
        forName: UIApplication.willResignActiveNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.hideScreenContent()
      }
      
      NotificationCenter.default.addObserver(
        forName: UIApplication.didBecomeActiveNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.showScreenContent()
      }
      
      // Observer pour l'enregistrement d'écran
      if #available(iOS 11.0, *) {
        NotificationCenter.default.addObserver(
          forName: UIScreen.capturedDidChangeNotification,
          object: nil,
          queue: .main
        ) { _ in
          if UIScreen.main.isCaptured {
            print("⚠️ Enregistrement d'écran détecté!")
            // Vous pouvez afficher un message ou masquer le contenu ici
          }
        }
      }
    }
  }
  
  // Overlay pour masquer le contenu
  private var securityView: UIView?
  
  private func hideScreenContent() {
    guard let window = self.window else { return }

    if securityView == nil {
      let view = UIView(frame: window.bounds)
      view.backgroundColor = UIColor(red: 0x1a/255.0, green: 0x1f/255.0, blue: 0x2e/255.0, alpha: 1.0)
      view.tag = 9999

      // Logo de l'app (asset Flutter)
      let assetKey = FlutterDartProject.lookupKey(forAsset: "assets/images/logo.png")
      let logoImage: UIImage?
      if let path = Bundle.main.path(forResource: assetKey, ofType: nil) {
        logoImage = UIImage(contentsOfFile: path)
      } else {
        logoImage = UIImage(named: "AppIcon")
      }

      let imageView = UIImageView(image: logoImage)
      imageView.contentMode = .scaleAspectFit
      imageView.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview(imageView)

      NSLayoutConstraint.activate([
        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        imageView.widthAnchor.constraint(equalToConstant: 120),
        imageView.heightAnchor.constraint(equalToConstant: 120),
      ])

      securityView = view
    }

    if let securityView = securityView {
      window.addSubview(securityView)
      window.bringSubviewToFront(securityView)
    }
  }
  
  private func showScreenContent() {
    securityView?.removeFromSuperview()
  }
}
