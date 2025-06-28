import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Unsaid Keyboard Extension
/// Provides platform channel integration for custom keyboard features,
/// including advanced analysis and real-time feedback.
class UnsaidKeyboardExtension {
  static const MethodChannel _channel = MethodChannel('unsaid_keyboard_extension');

  /// Checks if the custom keyboard is available/installed.
  static Future<bool> isKeyboardAvailable() async {
    try {
      final bool? result = await _channel.invokeMethod('isKeyboardAvailable');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error checking keyboard availability: ${e.message}');
      return false;
    }
  }

  /// Enables or disables the custom keyboard.
  static Future<bool> enableKeyboard(bool enable) async {
    try {
      final bool? result = await _channel.invokeMethod('enableKeyboard', {
        'enable': enable,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error enabling keyboard: ${e.message}');
      return false;
    }
  }

  /// Opens the device's keyboard settings.
  static Future<void> openKeyboardSettings() async {
    try {
      await _channel.invokeMethod('openKeyboardSettings');
    } on PlatformException catch (e) {
      print('Error opening keyboard settings: ${e.message}');
    }
  }

  /// Sends tone analysis results to the keyboard for real-time feedback.
  static Future<void> sendToneAnalysisPayload(Map<String, dynamic> payload) async {
    try {
      await _channel.invokeMethod('sendToneAnalysis', payload);
    } on PlatformException catch (e) {
      print('Error sending tone analysis: ${e.message}');
    }
  }

  /// Sends co-parenting analysis results to the keyboard.
  static Future<void> sendCoParentingAnalysis(
    String text,
    Map<String, dynamic> coParentingAnalysis,
  ) async {
    try {
      await _channel.invokeMethod('sendCoParentingAnalysis', {
        'text': text,
        'coParentingAnalysis': coParentingAnalysis,
      });
    } on PlatformException catch (e) {
      print('Error sending co-parenting analysis: ${e.message}');
    }
  }

  /// Sends child development analysis results to the keyboard.
  static Future<void> sendChildDevelopmentAnalysis(
    String text,
    Map<String, dynamic> childDevAnalysis,
  ) async {
    try {
      await _channel.invokeMethod('sendChildDevelopmentAnalysis', {
        'text': text,
        'childDevAnalysis': childDevAnalysis,
      });
    } on PlatformException catch (e) {
      print('Error sending child development analysis: ${e.message}');
    }
  }

  /// Sends emotional intelligence coaching results to the keyboard.
  static Future<void> sendEQCoaching(
    String text,
    Map<String, dynamic> eqCoaching,
  ) async {
    try {
      await _channel.invokeMethod('sendEQCoaching', {
        'text': text,
        'eqCoaching': eqCoaching,
      });
    } on PlatformException catch (e) {
      print('Error sending EQ coaching: ${e.message}');
    }
  }

  /// Gets the current keyboard status (enabled, permissions, etc.).
  static Future<Map<String, dynamic>> getKeyboardStatus() async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
        'getKeyboardStatus',
      );
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      print('Error getting keyboard status: ${e.message}');
      return {};
    }
  }

  /// Updates keyboard settings.
  static Future<bool> updateKeyboardSettings(
    Map<String, dynamic> settings,
  ) async {
    try {
      final bool? result = await _channel.invokeMethod(
        'updateKeyboardSettings',
        settings,
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error updating keyboard settings: ${e.message}');
      return false;
    }
  }

  /// Processes text input from the keyboard (e.g., for real-time suggestions).
  static Future<String> processTextInput(String text) async {
    try {
      final String? result = await _channel.invokeMethod('processTextInput', {
        'text': text,
      });
      return result ?? text;
    } on PlatformException catch (e) {
      print('Error processing text input: ${e.message}');
      return text;
    }
  }

  /// Checks if the user has enabled the keyboard in system settings.
  static Future<bool> isKeyboardEnabled() async {
    try {
      final bool? result = await _channel.invokeMethod('isKeyboardEnabled');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error checking if keyboard is enabled: ${e.message}');
      return false;
    }
  }

  /// Requests keyboard permissions from the user.
  static Future<bool> requestKeyboardPermissions() async {
    try {
      final bool? result = await _channel.invokeMethod(
        'requestKeyboardPermissions',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error requesting keyboard permissions: ${e.message}');
      return false;
    }
  }
}

/// Accessibility/UX Note:
/// When surfacing keyboard status or permissions in the UI,
/// use plain language and semantic labels for screen readers.

final openAIApiKey = dotenv.env['OPENAI_API_KEY'];
