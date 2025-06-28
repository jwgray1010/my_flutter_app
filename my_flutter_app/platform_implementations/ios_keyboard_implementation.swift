// iOS Implementation Guide for Unsaid Keyboard
// File: ios/Runner/UnsaidKeyboardPlugin.swift

import Flutter
import UIKit

public class UnsaidKeyboardPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "unsaid_keyboard", binaryMessenger: registrar.messenger())
        let instance = UnsaidKeyboardPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isKeyboardAvailable":
            result(isUnsaidKeyboardInstalled())
        case "isKeyboardEnabled":
            result(isUnsaidKeyboardEnabled())
        case "enableKeyboard":
            if let args = call.arguments as? [String: Any],
               let enable = args["enable"] as? Bool {
                result(enableUnsaidKeyboard(enable: enable))
            } else {
                result(false)
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
                result(false)
            }
        case "sendToneAnalysis":
            if let args = call.arguments as? [String: Any],
               let text = args["text"] as? String,
               let analysis = args["analysis"] as? [String: Any] {
                sendToneAnalysis(text: text, analysis: analysis)
            }
            result(nil)
        case "processTextInput":
            if let args = call.arguments as? [String: Any],
               let text = args["text"] as? String {
                result(processTextInput(text: text))
            } else {
                result(call.arguments as? String ?? "")
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func isUnsaidKeyboardInstalled() -> Bool {
        // Check if keyboard extension is installed
        // On iOS, this typically involves checking bundle identifier
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        let keyboardBundleId = "\(bundleId).KeyboardExtension"
        
        // Check if keyboard extension bundle exists
        if let extensionPath = Bundle.main.path(forResource: "KeyboardExtension", ofType: "appex") {
            return FileManager.default.fileExists(atPath: extensionPath)
        }
        
        return false
    }
    
    private func isUnsaidKeyboardEnabled() -> Bool {
        // On iOS, we can't reliably check if a keyboard is enabled
        // We can only direct users to settings
        return UserDefaults.standard.bool(forKey: "unsaid_keyboard_setup_complete")
    }
    
    private func enableUnsaidKeyboard(enable: Bool) -> Bool {
        // On iOS, keyboards must be enabled manually by users
        // We can only direct them to settings
        openKeyboardSettings()
        return true
    }
    
    private func openKeyboardSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
            }
        }
    }
    
    private func requestKeyboardPermissions() -> Bool {
        // Request full access permission if needed
        return isUnsaidKeyboardInstalled()
    }
    
    private func getKeyboardStatus() -> [String: Any] {
        return [
            "installed": isUnsaidKeyboardInstalled(),
            "enabled": isUnsaidKeyboardEnabled(),
            "active": isCurrentKeyboard()
        ]
    }
    
    private func isCurrentKeyboard() -> Bool {
        // This is challenging to detect on iOS
        // Return best guess based on setup status
        return UserDefaults.standard.bool(forKey: "unsaid_keyboard_active")
    }
    
    private func updateKeyboardSettings(settings: [String: Any]) -> Bool {
        // Store settings in app group shared container
        if let appGroup = UserDefaults(suiteName: "group.com.unsaid.keyboard") {
            for (key, value) in settings {
                appGroup.set(value, forKey: key)
            }
            appGroup.synchronize()
            
            // Notify keyboard extension of changes
            NotificationCenter.default.post(
                name: Notification.Name("UnsaidKeyboardSettingsChanged"),
                object: nil,
                userInfo: settings
            )
            
            return true
        }
        return false
    }
    
    private func sendToneAnalysis(text: String, analysis: [String: Any]) {
        // Send tone analysis to keyboard extension via app group
        if let appGroup = UserDefaults(suiteName: "group.com.unsaid.keyboard") {
            appGroup.set(text, forKey: "last_analyzed_text")
            appGroup.set(analysis, forKey: "last_tone_analysis")
            appGroup.set(Date().timeIntervalSince1970, forKey: "analysis_timestamp")
            appGroup.synchronize()
            
            // Notify keyboard extension
            NotificationCenter.default.post(
                name: Notification.Name("UnsaidToneAnalysisUpdate"),
                object: nil,
                userInfo: ["text": text, "analysis": analysis]
            )
        }
    }
    
    private func processTextInput(text: String) -> String {
        // Process text with tone analysis
        // This would integrate with your ML models
        return text
    }
}

/*
iOS KEYBOARD EXTENSION IMPLEMENTATION
File: KeyboardExtension/KeyboardViewController.swift

import UIKit

class KeyboardViewController: UIInputViewController {
    
    private var currentSettings: [String: Any] = [:]
    private var toneAnalysis: [String: Any] = [:]
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        // Add constraints for your keyboard layout
        setupKeyboardLayout()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadSettings()
        setupNotificationObservers()
        createKeyboardInterface()
    }
    
    private func loadSettings() {
        if let appGroup = UserDefaults(suiteName: "group.com.unsaid.keyboard") {
            // Load settings from shared container
            currentSettings = appGroup.dictionaryRepresentation()
        }
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: Notification.Name("UnsaidKeyboardSettingsChanged"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(toneAnalysisUpdated),
            name: Notification.Name("UnsaidToneAnalysisUpdate"),
            object: nil
        )
    }
    
    @objc private func settingsChanged(_ notification: Notification) {
        if let settings = notification.userInfo {
            currentSettings.merge(settings) { (_, new) in new }
            updateKeyboardAppearance()
        }
    }
    
    @objc private func toneAnalysisUpdated(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let analysis = userInfo["analysis"] as? [String: Any] {
            toneAnalysis = analysis
            updateToneIndicators()
        }
    }
    
    private func createKeyboardInterface() {
        // Create keyboard layout with tone indicators
        let keyboardView = createMainKeyboardView()
        let toneIndicatorView = createToneIndicatorView()
        let suggestionView = createSuggestionView()
        
        let stackView = UIStackView(arrangedSubviews: [toneIndicatorView, suggestionView, keyboardView])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func createMainKeyboardView() -> UIView {
        // Create QWERTY keyboard layout
        let keyboardView = UIView()
        keyboardView.backgroundColor = UIColor.systemGray6
        
        // Add keyboard buttons here
        // This would include standard QWERTY layout
        
        return keyboardView
    }
    
    private func createToneIndicatorView() -> UIView {
        let indicatorView = UIView()
        indicatorView.backgroundColor = UIColor.systemBackground
        indicatorView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        // Add tone indicator elements
        // Color-coded feedback, emoji indicators, etc.
        
        return indicatorView
    }
    
    private func createSuggestionView() -> UIView {
        let suggestionView = UIView()
        suggestionView.backgroundColor = UIColor.systemGray5
        suggestionView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        // Add suggestion buttons/text
        
        return suggestionView
    }
    
    private func setupKeyboardLayout() {
        // Configure keyboard size and constraints
        if let inputView = inputView {
            let height: CGFloat = 260 // Standard keyboard height
            let heightConstraint = inputView.heightAnchor.constraint(equalToConstant: height)
            heightConstraint.priority = UILayoutPriority(999)
            heightConstraint.isActive = true
        }
    }
    
    private func updateKeyboardAppearance() {
        // Update keyboard based on current settings
        // Theme, colors, layout changes, etc.
    }
    
    private func updateToneIndicators() {
        // Update tone indicators based on current analysis
        // Change colors, show warnings, suggestions, etc.
    }
    
    override func textWillChange(_ textInput: UITextInput?) {
        // Called before text changes
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        // Called after text changes
        if let proxy = textDocumentProxy {
            let currentText = proxy.documentContextBeforeInput ?? ""
            analyzeTone(text: currentText)
        }
    }
    
    private func analyzeTone(text: String) {
        // Send text back to main app for analysis
        // This would trigger the tone analysis pipeline
        
        // For now, we'll check for stored analysis
        if let appGroup = UserDefaults(suiteName: "group.com.unsaid.keyboard"),
           let lastText = appGroup.string(forKey: "last_analyzed_text"),
           text.contains(lastText) {
            if let analysis = appGroup.dictionary(forKey: "last_tone_analysis") {
                toneAnalysis = analysis
                updateToneIndicators()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

INFO.PLIST CONFIGURATION:
Add to KeyboardExtension/Info.plist:

<key>NSExtension</key>
<dict>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>IsASCIICapable</key>
        <true/>
        <key>PrefersRightToLeft</key>
        <false/>
        <key>PrimaryLanguage</key>
        <string>en-US</string>
        <key>RequestsOpenAccess</key>
        <true/>
    </dict>
    <key>NSExtensionMainStoryboard</key>
    <string>MainInterface</string>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.keyboard-service</string>
</dict>

APP GROUP CONFIGURATION:
1. Enable App Groups capability in both main app and keyboard extension
2. Use identifier: group.com.unsaid.keyboard
3. Share data via UserDefaults(suiteName:)
*/
