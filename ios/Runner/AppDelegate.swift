import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "tikboo/shared"
  private var sharedChannel: FlutterMethodChannel?
  // Holds a file shared before Flutter is ready to receive it (cold launch).
  private var pendingPath: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
    sharedChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "getInitialSharedFile" {
        result(self?.pendingPath)
        self?.pendingPath = nil
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // A chat opened the app cold (Export Chat → tikboo while not running).
    if let url = launchOptions?[.url] as? URL {
      pendingPath = copyIntoCache(url)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // A chat shared while tikboo is already running / backgrounded.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if let path = copyIntoCache(url) {
      if let channel = sharedChannel {
        channel.invokeMethod("onSharedFile", arguments: path)
      } else {
        pendingPath = path
      }
    }
    return true
  }

  /// Copies the incoming (possibly security-scoped) file into the app cache
  /// and returns a path Flutter can read.
  private func copyIntoCache(_ url: URL) -> String? {
    let scoped = url.startAccessingSecurityScopedResource()
    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
    do {
      let data = try Data(contentsOf: url)
      let dir = FileManager.default.temporaryDirectory
      let dest = dir.appendingPathComponent("tikboo_\(Int(Date().timeIntervalSince1970))_\(url.lastPathComponent)")
      try data.write(to: dest)
      return dest.path
    } catch {
      return nil
    }
  }
}
