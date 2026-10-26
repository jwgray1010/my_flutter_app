import Flutter
import UIKit
import AVFoundation
import Speech

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let voicePttController = VoicePttController()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register the custom keyboard plugin
    if let registrar = self.registrar(forPlugin: "UnsaidKeyboardPlugin") {
        UnsaidKeyboardPlugin.register(with: registrar)
    }

    if let registrar = self.registrar(forPlugin: "ChoirVoicePttPlugin") {
      let voiceChannel = FlutterMethodChannel(
        name: "choir_voice_ptt",
        binaryMessenger: registrar.messenger()
      )
      voiceChannel.setMethodCallHandler { [weak self] call, result in
        self?.voicePttController.handle(call: call, result: result)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

final class VoicePttController: NSObject {
  private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
  private let audioEngine = AVAudioEngine()
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  private var recognitionTask: SFSpeechRecognitionTask?
  private var latestTranscript: String = ""
  private var latestConfidence: Float = 0
  private var pendingStopResult: FlutterResult?
  private var finishWorkItem: DispatchWorkItem?
  private var usingOnDeviceRecognition: Bool = false
  private var isListening: Bool = false

  func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestPermissions":
      requestPermissions(result: result)
    case "startListening":
      let args = (call.arguments as? [String: Any]) ?? [:]
      startListening(args: args, result: result)
    case "stopListening":
      stopListening(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func requestPermissions(result: @escaping FlutterResult) {
    let group = DispatchGroup()
    var speechAuthorized = false
    var micAuthorized = false

    group.enter()
    SFSpeechRecognizer.requestAuthorization { status in
      speechAuthorized = (status == .authorized)
      group.leave()
    }

    group.enter()
    AVAudioSession.sharedInstance().requestRecordPermission { granted in
      micAuthorized = granted
      group.leave()
    }

    group.notify(queue: .main) {
      result([
        "authorized": speechAuthorized && micAuthorized,
        "speechAuthorized": speechAuthorized,
        "micAuthorized": micAuthorized
      ])
    }
  }

  private func startListening(args: [String: Any], result: @escaping FlutterResult) {
    if isListening {
      finishCurrentSession()
    }

    let speechStatus = SFSpeechRecognizer.authorizationStatus()
    let micGranted = AVAudioSession.sharedInstance().recordPermission == .granted
    guard speechStatus == .authorized, micGranted else {
      result([
        "started": false,
        "usingOnDevice": false,
        "message": "Speech or microphone permission missing."
      ])
      return
    }
    guard let speechRecognizer, speechRecognizer.isAvailable else {
      result([
        "started": false,
        "usingOnDevice": false,
        "message": "Speech recognizer unavailable."
      ])
      return
    }

    let preferOffline = (args["preferOffline"] as? Bool) ?? true
    let allowStandardFallback = (args["allowStandardFallback"] as? Bool) ?? true

    latestTranscript = ""
    latestConfidence = 0
    usingOnDeviceRecognition = false
    pendingStopResult = nil
    finishWorkItem?.cancel()
    finishWorkItem = nil

    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

      recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
      guard let recognitionRequest else {
        result([
          "started": false,
          "usingOnDevice": false,
          "message": "Failed to create recognition request."
        ])
        return
      }
      recognitionRequest.shouldReportPartialResults = true

      if speechRecognizer.supportsOnDeviceRecognition {
        // Prefer offline on-device recognition for rehearsal reliability.
        recognitionRequest.requiresOnDeviceRecognition = preferOffline
        usingOnDeviceRecognition = recognitionRequest.requiresOnDeviceRecognition
      } else {
        if preferOffline && !allowStandardFallback {
          result([
            "started": false,
            "usingOnDevice": false,
            "message": "On-device speech not available on this device."
          ])
          return
        }
        recognitionRequest.requiresOnDeviceRecognition = false
        usingOnDeviceRecognition = false
      }

      let inputNode = audioEngine.inputNode
      let recordingFormat = inputNode.outputFormat(forBus: 0)
      inputNode.removeTap(onBus: 0)
      inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
        self?.recognitionRequest?.append(buffer)
      }

      audioEngine.prepare()
      try audioEngine.start()

      recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] recognitionResult, recognitionError in
        guard let self else { return }

        if let recognitionResult {
          self.latestTranscript = recognitionResult.bestTranscription.formattedString
          self.latestConfidence = self.averageConfidence(recognitionResult.bestTranscription)
          if recognitionResult.isFinal {
            self.finishStopIfNeeded(errorMessage: nil)
          }
        }

        if let recognitionError {
          self.finishStopIfNeeded(errorMessage: recognitionError.localizedDescription)
        }
      }

      isListening = true
      result([
        "started": true,
        "usingOnDevice": usingOnDeviceRecognition,
        "message": usingOnDeviceRecognition ? "Listening on-device." : "Listening."
      ])
    } catch {
      finishCurrentSession()
      result([
        "started": false,
        "usingOnDevice": false,
        "message": "Audio start failed: \(error.localizedDescription)"
      ])
    }
  }

  private func stopListening(result: @escaping FlutterResult) {
    if !isListening {
      result([
        "transcript": latestTranscript,
        "confidence": latestConfidence,
        "usedOnDevice": usingOnDeviceRecognition,
        "error": latestTranscript.isEmpty ? "No active recording." : NSNull()
      ])
      return
    }

    pendingStopResult = result
    finishWorkItem?.cancel()
    finishWorkItem = nil

    if audioEngine.isRunning {
      audioEngine.stop()
    }
    audioEngine.inputNode.removeTap(onBus: 0)
    recognitionRequest?.endAudio()

    let fallback = DispatchWorkItem { [weak self] in
      self?.finishStopIfNeeded(errorMessage: nil)
    }
    finishWorkItem = fallback
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9, execute: fallback)
  }

  private func finishStopIfNeeded(errorMessage: String?) {
    guard let callback = pendingStopResult else {
      return
    }
    pendingStopResult = nil
    finishWorkItem?.cancel()
    finishWorkItem = nil

    let trimmedTranscript = latestTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
    callback([
      "transcript": trimmedTranscript,
      "confidence": latestConfidence,
      "usedOnDevice": usingOnDeviceRecognition,
      "error": trimmedTranscript.isEmpty ? (errorMessage ?? "No speech recognized.") : NSNull()
    ])

    finishCurrentSession()
  }

  private func finishCurrentSession() {
    if audioEngine.isRunning {
      audioEngine.stop()
    }
    audioEngine.inputNode.removeTap(onBus: 0)
    recognitionRequest?.endAudio()
    recognitionTask?.cancel()
    recognitionTask = nil
    recognitionRequest = nil
    isListening = false
    do {
      try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    } catch {
      // Keep MVP flow resilient even if session deactivation fails.
    }
  }

  private func averageConfidence(_ transcription: SFTranscription) -> Float {
    let segments = transcription.segments
    if segments.isEmpty {
      return 0.5
    }
    let values = segments.map { max(0, $0.confidence) }
    guard !values.isEmpty else {
      return 0.5
    }
    let sum = values.reduce(0, +)
    return sum / Float(values.count)
  }
}
