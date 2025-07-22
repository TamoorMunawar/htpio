import Flutter
import UIKit

public class HtpioPlugin: NSObject, FlutterPlugin {

    // Register the plugin with the Flutter engine
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "htpio", binaryMessenger: registrar.messenger())
        let instance = HtpioPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    // Handle method calls from Flutter
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "getPlatformVersion" {
            // Respond with the iOS version
            result("iOS " + UIDevice.current.systemVersion)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
}
