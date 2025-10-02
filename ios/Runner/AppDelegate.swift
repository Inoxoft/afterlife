import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Set up a MethodChannel to call native iOS foundation model from Flutter
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "afterlife/native_ai",
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "isFMAvailable":
          result(NativeAI.isFoundationModelsAvailable)
        case "fmStatus":
          let status = NativeAI.shared.getStatus()
          result(["available": status.available, "reason": status.reason])
        case "generateText":
          guard
            let args = call.arguments as? [String: Any],
            let prompt = args["prompt"] as? String
          else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing 'prompt'", details: nil))
            return
          }

          // Route through NativeAI wrapper (uses FoundationModels when available)
          NativeAI.shared.generateText(prompt: prompt) { generated in
            switch generated {
            case .success(let text):
              result(text)
            case .failure(let error):
              result(FlutterError(code: "GEN_FAIL", message: error.localizedDescription, details: nil))
            }
          }

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
