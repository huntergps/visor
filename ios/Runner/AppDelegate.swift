import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let printerManager = ZebraPrinterManager()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Register Bluetooth method channel (same channel name as Android)
    let controller = window?.rootViewController as! FlutterViewController
    let btChannel = FlutterMethodChannel(
      name: "tech.galapagos.theosvisor/bluetooth",
      binaryMessenger: controller.binaryMessenger
    )

    btChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }

      switch call.method {
      case "getPairedDevices":
        self.printerManager.getPairedDevices(result: result)

      case "connect":
        let args = call.arguments as? [String: Any]
        let address = args?["address"] as? String ?? ""
        self.printerManager.connect(address: address, result: result)

      case "send":
        let args = call.arguments as? [String: Any]
        let data = args?["data"] as? String ?? ""
        self.printerManager.send(data: data, result: result)

      case "disconnect":
        self.printerManager.disconnect(result: result)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
