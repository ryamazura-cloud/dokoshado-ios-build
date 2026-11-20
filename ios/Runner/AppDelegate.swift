import Flutter
import UIKit
import AppTrackingTransparency
import UserNotifications
import StoreKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var purchases: StorePurchases?
  private var privacyChannel: FlutterMethodChannel?
  private var reviewChannel: FlutterMethodChannel?
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
    let review = FlutterMethodChannel(
      name: "biz.wisemap.dokoshado/review", binaryMessenger: messenger)
    review.setMethodCallHandler { call, result in
      guard call.method == "requestReview" else {
        result(FlutterMethodNotImplemented)
        return
      }
      DispatchQueue.main.async {
        if let scene = UIApplication.shared.connectedScenes
          .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
          if #available(iOS 18.0, *) {
            AppStore.requestReview(in: scene)
          } else {
            SKStoreReviewController.requestReview(in: scene)
          }
        }
        result(nil)
      }
    }
    reviewChannel = review
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
