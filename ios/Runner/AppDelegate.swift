import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // TODO(maps): Google Maps SDK for iOS key. Enable "Maps SDK for iOS" in
    // Google Cloud, create an iOS-restricted key, and paste it below (or read
    // it from a config/secret). Separate from GOOGLE_PLACES_API_KEY.
    GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
