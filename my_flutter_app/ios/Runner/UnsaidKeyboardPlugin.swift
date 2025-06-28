import Flutter
import UIKit

public class UnsaidKeyboardPlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "unsaid_keyboard", binaryMessenger: registrar.messenger())
        let instance = UnsaidKeyboardPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isKeyboardAvailable":
            result(isKeyboardAvailable())
        case "isKeyboardEnabled":
            result(isKeyboardEnabled())
        case "enableKeyboard":
            if let args = call.arguments as? [String: Any],
               let enable = args["enable"] as? Bool {
                result(enableKeyboard(enable: enable))
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            }
        case "openKeyboardSettings":
            openKeyboardSettings()
            result(nil)
        case "requestKeyboardPermissions":
            result(requestKeyboardPermissions())
        case "getKeyboardStatus":
            result(getKeyboardStatus())
        case "updateKeyboardSettings":
            if let settings = call.arguments as? [String: Any] {
                result(updateKeyboardSettings(settings: settings))
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            }
        case "sendToneAnalysis":
            if let args = call.arguments as? [String: Any],
               let text = args["text"] as? String,
               let analysis = args["analysis"] as? [String: Any] {
                sendToneAnalysis(text: text, analysis: analysis)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            }
        case "processTextInput":
            if let args = call.arguments as? [String: Any],
               let text = args["text"] as? String {
                result(processTextInput(text: text))
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func isKeyboardAvailable() -> Bool {
        // Check if the keyboard extension is bundled with the app
        guard let bundleURL = Bundle.main.url(forResource: "KeyboardExtension", withExtension: "appex", subdirectory: "PlugIns") else {
            return false
        }
        return FileManager.default.fileExists(atPath: bundleURL.path)
    }
    
    private func isKeyboardEnabled() -> Bool {
        // On iOS, we can't directly check if a custom keyboard is enabled
        // We can only check if we have the keyboard extension available
        return isKeyboardAvailable()
    }
    
    private func enableKeyboard(enable: Bool) -> Bool {
        // On iOS, users must manually enable keyboards in Settings
        // We can only direct them to the keyboard settings
        openKeyboardSettings()
        return true
    }
    
    private func openKeyboardSettings() {
        DispatchQueue.main.async {
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: nil)
                }
            }
        }
    }
    
    private func requestKeyboardPermissions() -> Bool {
        // iOS keyboards don't require special permissions
        return isKeyboardAvailable()
    }
    
    private func getKeyboardStatus() -> [String: Any] {
        return [
            "installed": isKeyboardAvailable(),
            "enabled": isKeyboardEnabled(),
            "active": false // Can't reliably detect if our keyboard is currently active
        ]
    }
    
    private func updateKeyboardSettings(settings: [String: Any]) -> Bool {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.unsaid.keyboard") else {
            return false
        }
        
        for (key, value) in settings {
            sharedDefaults.set(value, forKey: key)
        }
        
        return sharedDefaults.synchronize()
    }
    
    private func sendToneAnalysis(text: String, analysis: [String: Any]) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.unsaid.keyboard") else {
            return
        }
        
        // Store the analysis data for the keyboard extension
        sharedDefaults.set(text, forKey: "analyzed_text")
        
        if let dominantTone = analysis["dominant_tone"] as? String {
            sharedDefaults.set(dominantTone, forKey: "dominant_tone")
        }
        
        if let confidence = analysis["confidence"] as? Double {
            sharedDefaults.set(confidence, forKey: "confidence")
        }
        
        sharedDefaults.set(Date().timeIntervalSince1970, forKey: "tone_analysis_timestamp")
        sharedDefaults.synchronize()
        
        // Notify the keyboard extension
        NotificationCenter.default.post(name: Notification.Name("UnsaidToneAnalysisUpdate"), object: nil)
    }
    
    private func processTextInput(text: String) -> String {
        // For now, return the original text
        // In production, apply tone corrections here
        return text
    }
}
