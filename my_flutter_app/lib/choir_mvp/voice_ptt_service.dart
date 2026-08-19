import 'package:flutter/services.dart';

class PttStartResult {
  const PttStartResult({
    required this.started,
    required this.usingOnDevice,
    required this.message,
  });

  final bool started;
  final bool usingOnDevice;
  final String message;
}

class PttStopResult {
  const PttStopResult({
    required this.transcript,
    required this.confidence,
    required this.usedOnDevice,
    this.error,
  });

  final String transcript;
  final double confidence;
  final bool usedOnDevice;
  final String? error;
}

class VoicePttService {
  static const MethodChannel _channel = MethodChannel('choir_voice_ptt');

  Future<bool> requestPermissions() async {
    try {
      final raw = await _channel.invokeMethod<dynamic>('requestPermissions');
      final map = _toStringDynamicMap(raw);
      return map['authorized'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<PttStartResult> startListening({
    bool preferOffline = true,
    bool allowStandardFallback = true,
  }) async {
    try {
      final raw = await _channel.invokeMethod<dynamic>('startListening', {
        'preferOffline': preferOffline,
        'allowStandardFallback': allowStandardFallback,
      });
      final map = _toStringDynamicMap(raw);
      return PttStartResult(
        started: map['started'] == true,
        usingOnDevice: map['usingOnDevice'] == true,
        message: (map['message']?.toString() ?? 'Voice ready').trim(),
      );
    } catch (error) {
      return PttStartResult(
        started: false,
        usingOnDevice: false,
        message: 'Voice unavailable: $error',
      );
    }
  }

  Future<PttStopResult> stopListening() async {
    try {
      final raw = await _channel.invokeMethod<dynamic>('stopListening');
      final map = _toStringDynamicMap(raw);
      return PttStopResult(
        transcript: (map['transcript']?.toString() ?? '').trim(),
        confidence: _toDouble(map['confidence']) ?? 0,
        usedOnDevice: map['usedOnDevice'] == true,
        error: map['error']?.toString(),
      );
    } catch (error) {
      return PttStopResult(
        transcript: '',
        confidence: 0,
        usedOnDevice: false,
        error: 'Stop failed: $error',
      );
    }
  }

  Map<String, dynamic> _toStringDynamicMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    return <String, dynamic>{};
  }

  double? _toDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}

