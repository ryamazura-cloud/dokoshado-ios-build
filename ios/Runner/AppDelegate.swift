import Flutter
import UIKit
import AppTrackingTransparency
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var purchases: StorePurchases?
  private var privacyChannel: FlutterMethodChannel?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()
    purchases = StorePurchases(channel: FlutterMethodChannel(
      name: "biz.wisemap.dokoshado/purchases", binaryMessenger: messenger))
    let privacy = FlutterMethodChannel(
      name: "biz.wisemap.dokoshado/privacy", binaryMessenger: messenger)
    privacy.setMethodCallHandler { call, result in
      guard call.method == "requestTracking" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard UIApplication.shared.applicationState == .active,
            ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
        result(nil)
        return
      }
      ATTrackingManager.requestTrackingAuthorization { _ in
        DispatchQueue.main.async { result(nil) }
      }
    }
    privacyChannel = privacy
  }
}
