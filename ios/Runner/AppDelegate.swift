import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps SDK key, read from Info.plist (GMSApiKey), which is
    // substituted from Secrets.xcconfig (gitignored) at build time. Empty when
    // no key is provided (map renders gray). Separate from GOOGLE_PLACES_API_KEY.
    let mapsApiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String ?? ""
    GMSServices.provideAPIKey(mapsApiKey)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // With the UIScene lifecycle the engine is created after launch finishes,
  // so plugins register against it here instead of against `self`.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
