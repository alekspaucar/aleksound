import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var nativeMusic: NativeMusicPlugin?
  private var pendingBackgroundCompletion: (() -> Void)?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AleksoundNativeMusic") {
      nativeMusic = NativeMusicPlugin(messenger: registrar.messenger())
      if let completion = pendingBackgroundCompletion {
        nativeMusic?.handleBackgroundEvents(completion)
        pendingBackgroundCompletion = nil
      }
    }
  }

  override func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
    if identifier == "aleksound.audio.downloads" {
      if let nativeMusic = nativeMusic { nativeMusic.handleBackgroundEvents(completionHandler) }
      else { pendingBackgroundCompletion = completionHandler }
    } else {
      super.application(application, handleEventsForBackgroundURLSession: identifier, completionHandler: completionHandler)
    }
  }
}
