import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef CommandHandler = FutureOr<void> Function(Map<String, dynamic> command);
typedef StateSnapshotBuilder = Map<String, dynamic> Function();
typedef PlayerNameBuilder = String Function();
typedef ClientConnectionHandler = void Function(String clientId, bool connected);

class LocalPlayerServer {
  LocalPlayerServer({
    this.port = 8743,
  });

  final int port;
  String _pairToken = '';

  HttpServer? _httpServer;
  final Set<WebSocket> _authedClients = <WebSocket>{};
  CommandHandler? _commandHandler;
  StateSnapshotBuilder? _stateSnapshotBuilder;
  PlayerNameBuilder? _playerNameBuilder;
  ClientConnectionHandler? _clientConnectionHandler;
  Timer? _stateTickTimer;
  String _lastKnownIp = '127.0.0.1';
  String? _classSessionToken;
  final Map<WebSocket, String> _clientIdBySocket = <WebSocket, String>{};

  bool get isRunning => _httpServer != null;

  // Compatibility with previous API.
  int get commandPort => port;
  int get announcePort => 0;

  Future<void> start({
    required CommandHandler onCommand,
    required StateSnapshotBuilder stateBuilder,
    PlayerNameBuilder? playerNameBuilder,
    ClientConnectionHandler? onClientConnectionChanged,
  }) async {
    if (isRunning) {
      return;
    }
    _commandHandler = onCommand;
    _stateSnapshotBuilder = stateBuilder;
    _playerNameBuilder = playerNameBuilder;
    _clientConnectionHandler = onClientConnectionChanged;
    _pairToken = await _loadOrCreateServerToken();

    _httpServer = await HttpServer.bind(
      InternetAddress.anyIPv4,
      port,
      shared: true,
    );
    _httpServer!.listen(
      _handleHttpRequest,
      onError: (_) {},
      onDone: () {},
    );

    _lastKnownIp = await _resolveLanIp();
    _stateTickTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _broadcastStateWhilePlaying(),
    );
  }

  Future<Map<String, dynamic>> buildPairingPayload({
    Map<String, dynamic>? extra,
    String? overrideToken,
  }) async {
    if (isRunning) {
      _lastKnownIp = await _resolveLanIp();
    }
    final payload = <String, dynamic>{
      'name': _playerNameBuilder?.call() ?? 'ChoirPlayer-iPad',
      'ip': _lastKnownIp,
      'port': port,
      'token': overrideToken ?? _classSessionToken ?? _pairToken,
    };
    if (extra != null) {
      payload.addAll(extra);
    }
    return payload;
  }

  void setClassSessionToken(String? token) {
    _classSessionToken = token;
  }

  void broadcastState() {
    final builder = _stateSnapshotBuilder;
    if (builder == null || _authedClients.isEmpty) {
      return;
    }
    final message = <String, dynamic>{
      'type': 'STATE',
      'payload': builder(),
    };
    _broadcastJson(message);
  }

  Future<void> stop() async {
    _stateTickTimer?.cancel();
    _stateTickTimer = null;

    final sockets = _authedClients.toList();
    _authedClients.clear();
    for (final socket in sockets) {
      try {
        await socket.close();
      } catch (_) {}
    }

    final server = _httpServer;
    _httpServer = null;
    if (server != null) {
      await server.close(force: true);
    }
  }

  Future<void> _handleHttpRequest(HttpRequest request) async {
    if (request.uri.path == '/ws' && WebSocketTransformer.isUpgradeRequest(request)) {
      final socket = await WebSocketTransformer.upgrade(request);
      _handleWebSocket(socket);
      return;
    }

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.text
      ..write('Choir Player Server')
      ..close();
  }

  void _handleWebSocket(WebSocket socket) {
    var authenticated = false;
    final clientId = _newClientId();

    socket.listen(
      (event) async {
        final decoded = _decodeMap(event);
        if (decoded == null) {
          return;
        }

        if (!authenticated) {
          final isAuth = decoded['type'] == 'AUTH';
          final token = decoded['token']?.toString() ?? '';
          final tokenOk = token == _pairToken || (_classSessionToken != null && token == _classSessionToken);
          if (!isAuth || !tokenOk) {
            _sendJson(socket, <String, dynamic>{
              'type': 'ERROR',
              'message': 'TOKEN_MISMATCH',
            });
            await socket.close(WebSocketStatus.policyViolation, 'TOKEN_MISMATCH');
            return;
          }
          authenticated = true;
          _authedClients.add(socket);
          _clientIdBySocket[socket] = clientId;
          _clientConnectionHandler?.call(clientId, true);
          _sendJson(socket, <String, dynamic>{
            'type': 'AUTH_OK',
            'name': _playerNameBuilder?.call() ?? 'ChoirPlayer-iPad',
          });
          _sendStateTo(socket);
          return;
        }

        final messageType = decoded['type']?.toString() ?? '';
        final handler = _commandHandler;
        if (handler == null) {
          return;
        }
        if (messageType == 'COMMAND') {
          final command = _translateEnvelopeToCommand(decoded);
          if (command == null) {
            return;
          }
          command['_clientId'] = clientId;
          await handler(command);
          broadcastState();
          return;
        }
        if (_isStudentEventType(messageType)) {
          final event = <String, dynamic>{
            ...decoded,
            '_clientId': clientId,
          };
          await handler(event);
          broadcastState();
        }
      },
      onDone: () => _removeSocket(socket),
      onError: (_) => _removeSocket(socket),
      cancelOnError: true,
    );
  }

  void _removeSocket(WebSocket socket) {
    final clientId = _clientIdBySocket.remove(socket);
    if (clientId != null) {
      _clientConnectionHandler?.call(clientId, false);
    }
    _authedClients.remove(socket);
    try {
      socket.close();
    } catch (_) {}
  }

  void _broadcastStateWhilePlaying() {
    final builder = _stateSnapshotBuilder;
    if (builder == null || _authedClients.isEmpty) {
      return;
    }
    final snapshot = builder();
    if (snapshot['isPlaying'] == true) {
      _broadcastJson(<String, dynamic>{
        'type': 'STATE',
        'payload': snapshot,
      });
    }
  }

  void _sendStateTo(WebSocket socket) {
    final builder = _stateSnapshotBuilder;
    if (builder == null) {
      return;
    }
    _sendJson(socket, <String, dynamic>{
      'type': 'STATE',
      'payload': builder(),
    });
  }

  void _broadcastJson(Map<String, dynamic> message) {
    final dead = <WebSocket>[];
    for (final socket in _authedClients) {
      try {
        _sendJson(socket, message);
      } catch (_) {
        dead.add(socket);
      }
    }
    for (final socket in dead) {
      _removeSocket(socket);
    }
  }

  void _sendJson(WebSocket socket, Map<String, dynamic> data) {
    socket.add(jsonEncode(data));
  }

  Map<String, dynamic>? _decodeMap(Object? value) {
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return decoded.cast<String, dynamic>();
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic>? _translateEnvelopeToCommand(Map<String, dynamic> envelope) {
    final command = envelope['command']?.toString() ?? '';
    final args = envelope['args'];
    final argsMap = args is Map ? args.cast<String, dynamic>() : <String, dynamic>{};

    switch (command) {
      case 'PLAY':
        return <String, dynamic>{'type': 'PLAY'};
      case 'PAUSE':
        return <String, dynamic>{'type': 'PAUSE'};
      case 'TOGGLE_PLAY':
        return <String, dynamic>{'type': 'TOGGLE_PLAY'};
      case 'JUMP_TO_MEASURE':
        return <String, dynamic>{
          'type': 'JUMP_TO_MEASURE',
          'measure': argsMap['measure'],
          'autoPlay': argsMap['autoPlay'] == true,
        };
      case 'JUMP_RELATIVE':
        return <String, dynamic>{
          'type': 'JUMP_RELATIVE',
          'deltaMeasures': argsMap['deltaMeasures'],
        };
      case 'SET_TEMPO_PERCENT':
        return <String, dynamic>{
          'type': 'SET_TEMPO',
          'percent': argsMap['percent'],
        };
      case 'ADJUST_TEMPO_PERCENT':
        return <String, dynamic>{
          'type': 'SET_TEMPO_ADJUST',
          'delta': argsMap['deltaPercent'],
        };
      case 'SET_LOOP_A':
        return <String, dynamic>{
          'type': 'SET_LOOP_A',
          'measure': argsMap['measure'],
        };
      case 'SET_LOOP_B':
        return <String, dynamic>{
          'type': 'SET_LOOP_B',
          'measure': argsMap['measure'],
        };
      case 'SET_LOOP_RANGE':
        return <String, dynamic>{
          'type': 'SET_LOOP_RANGE',
          'a': argsMap['a'],
          'b': argsMap['b'],
        };
      case 'CLEAR_LOOP':
        return <String, dynamic>{'type': 'CLEAR_LOOP'};
      case 'SET_PART_ENABLED':
        return <String, dynamic>{
          'type': 'SET_PART_ENABLED',
          'part': _protocolPartToInternal(argsMap['part']),
          'enabled': argsMap['enabled'],
        };
      case 'SET_PARTS_ENABLED':
        return <String, dynamic>{
          'type': 'SET_PARTS_ENABLED',
          'partsEnabledSet': argsMap['partsEnabledSet'],
          'pianoEnabled': argsMap['pianoEnabled'],
        };
      case 'SET_MIX_PRESET':
        return <String, dynamic>{
          'type': 'SET_MIX_PRESET',
          'preset': argsMap['preset'],
          'parts': argsMap['parts'],
          'pianoOn': argsMap['pianoEnabled'],
        };
      case 'PLAY_STARTING_PITCHES':
        return <String, dynamic>{'type': 'PLAY_STARTING_PITCHES'};
      case 'LOOP_ARM_TOGGLE':
        return <String, dynamic>{'type': 'LOOP_ARM_TOGGLE'};
      default:
        return null;
    }
  }

  String _protocolPartToInternal(Object? raw) {
    switch (raw?.toString().toUpperCase()) {
      case 'SOP':
        return 'soprano';
      case 'ALTO':
        return 'alto';
      case 'TENOR':
        return 'tenor';
      case 'BASS':
        return 'bass';
      case 'PIANO':
        return 'piano';
      default:
        return raw?.toString().toLowerCase() ?? '';
    }
  }

  bool _isStudentEventType(String type) {
    return type == 'REGISTER_STATION' ||
        type == 'JOIN_STATION' ||
        type == 'PRACTICE_COMPLETED' ||
        type == 'CHECKIN_ATTEMPT' ||
        type == 'JOIN_CLASS_SESSION' ||
        type == 'START_PRACTICE_SESSION' ||
        type == 'PRACTICE_EVENT' ||
        type == 'PRACTICE_SUMMARY';
  }

  String _newClientId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = Random.secure().nextInt(1 << 32);
    return 'c$now-$rand';
  }

  static String _generateToken() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    return List<String>.generate(32, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<String> _loadOrCreateServerToken() async {
    const tokenKey = 'choir_player_pair_token_v1';
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(tokenKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final created = _generateToken();
    await prefs.setString(tokenKey, created);
    return created;
  }

  Future<String> _resolveLanIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (_isPrivateIp(address.address)) {
            return address.address;
          }
        }
      }
      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        return interfaces.first.addresses.first.address;
      }
    } catch (_) {}
    return '127.0.0.1';
  }

  bool _isPrivateIp(String ip) {
    if (ip.startsWith('10.')) {
      return true;
    }
    if (ip.startsWith('192.168.')) {
      return true;
    }
    if (ip.startsWith('172.')) {
      final segments = ip.split('.');
      final second = segments.length > 1 ? int.tryParse(segments[1]) : null;
      if (second != null && second >= 16 && second <= 31) {
        return true;
      }
    }
    return false;
  }
}

class PlayerPairingProfile {
  const PlayerPairingProfile({
    required this.name,
    required this.ip,
    required this.port,
    required this.token,
    this.mode,
    this.sessionId,
    this.stationId,
    this.stationName,
    this.lockedPart,
    this.stationPasscode,
    this.practice,
  });

  final String name;
  final String ip;
  final int port;
  final String token;
  final String? mode;
  final String? sessionId;
  final String? stationId;
  final String? stationName;
  final String? lockedPart;
  final String? stationPasscode;
  final Map<String, dynamic>? practice;

  factory PlayerPairingProfile.fromMap(Map<String, dynamic> map) {
    return PlayerPairingProfile(
      name: map['name']?.toString() ?? 'ChoirPlayer-iPad',
      ip: map['ip']?.toString() ?? '',
      port: (map['port'] is int)
          ? map['port'] as int
          : int.tryParse(map['port']?.toString() ?? '') ?? 8743,
      token: map['token']?.toString() ?? '',
      mode: map['mode']?.toString(),
      sessionId: map['sessionId']?.toString(),
      stationId: map['stationId']?.toString(),
      stationName: map['stationName']?.toString(),
      lockedPart: map['lockedPart']?.toString(),
      stationPasscode: map['stationPasscode']?.toString(),
      practice: map['practice'] is Map
          ? (map['practice'] as Map).cast<String, dynamic>()
          : null,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'name': name,
    'ip': ip,
    'port': port,
    'token': token,
    if (mode != null) 'mode': mode,
    if (sessionId != null) 'sessionId': sessionId,
    if (stationId != null) 'stationId': stationId,
    if (stationName != null) 'stationName': stationName,
    if (lockedPart != null) 'lockedPart': lockedPart,
    if (stationPasscode != null) 'stationPasscode': stationPasscode,
    if (practice != null) 'practice': practice,
  };
}

class DiscoveredPlayer {
  const DiscoveredPlayer({
    required this.host,
    required this.port,
    required this.lastSeen,
  });

  final String host;
  final int port;
  final DateTime lastSeen;
}

class RemoteClient extends ChangeNotifier {
  RemoteClient({this.announcePort = 45455});

  static const String _pairedProfilePrefsKey = 'choir_remote_paired_profile_v1';
  static const String _deviceIdPrefsKey = 'choir_remote_device_id_v1';

  final int announcePort;
  final List<DiscoveredPlayer> _discoveredPlayers = const <DiscoveredPlayer>[];

  WebSocket? _socket;
  StreamSubscription<dynamic>? _socketSubscription;
  Timer? _reconnectTimer;
  PlayerPairingProfile? _pairedProfile;
  Map<String, dynamic>? _latestState;

  bool _connecting = false;
  bool _authenticated = false;
  bool _manualDisconnect = false;
  String? _connectionStatus;
  String? _deviceId;

  Map<String, dynamic>? get latestState => _latestState;
  String? get connectedHost => _pairedProfile?.ip;
  int? get connectedPort => _pairedProfile?.port;
  String? get connectionStatus => _connectionStatus;
  bool get isConnected => _socket != null && _authenticated;
  bool get isConnecting => _connecting;
  PlayerPairingProfile? get pairedProfile => _pairedProfile;
  List<DiscoveredPlayer> get discoveredPlayers => _discoveredPlayers;
  String get deviceId {
    final existing = _deviceId;
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final created = _generateId('device');
    _deviceId = created;
    unawaited(_saveDeviceId(created));
    return created;
  }

  Future<void> startDiscovery() async {
    // Discovery intentionally disabled for MVP reliability.
  }

  Future<void> restoreAndReconnect() async {
    await _ensureDeviceIdLoaded();
    await loadSavedPairing();
    await connectPaired();
  }

  Future<void> loadSavedPairing() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pairedProfilePrefsKey);
    if (raw == null || raw.isEmpty) {
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        _pairedProfile = PlayerPairingProfile.fromMap(decoded.cast<String, dynamic>());
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> pairFromPayload(
    Map<String, dynamic> payload, {
    bool connectNow = true,
  }) async {
    final profile = PlayerPairingProfile.fromMap(payload);
    _pairedProfile = profile;
    await _savePairingProfile(profile);
    notifyListeners();
    if (connectNow) {
      await connectPaired();
    }
  }

  void sendStudentMessage(
    String type, {
    Map<String, dynamic> payload = const <String, dynamic>{},
  }) {
    final socket = _socket;
    if (socket == null || !_authenticated) {
      _connectionStatus = 'Not connected';
      notifyListeners();
      return;
    }
    try {
      socket.add(
        jsonEncode(<String, dynamic>{
          'type': type,
          ...payload,
        }),
      );
    } catch (_) {
      _handleDisconnect('Failed to send message');
    }
  }

  Future<void> pairFromQrText(String rawPayload) async {
    final decoded = jsonDecode(rawPayload);
    if (decoded is! Map) {
      throw const FormatException('QR payload is not JSON object');
    }
    await pairFromPayload(decoded.cast<String, dynamic>());
  }

  Future<void> connectPaired() async {
    final profile = _pairedProfile;
    if (profile == null) {
      _connectionStatus = 'No paired player';
      notifyListeners();
      return;
    }
    await connect(
      host: profile.ip,
      port: profile.port,
      token: profile.token,
      name: profile.name,
      mode: profile.mode,
      sessionId: profile.sessionId,
      stationId: profile.stationId,
      stationName: profile.stationName,
      lockedPart: profile.lockedPart,
      stationPasscode: profile.stationPasscode,
      practice: profile.practice,
      persist: true,
    );
  }

  Future<void> connect({
    required String host,
    required int port,
    String? token,
    String? name,
    String? mode,
    String? sessionId,
    String? stationId,
    String? stationName,
    String? lockedPart,
    String? stationPasscode,
    Map<String, dynamic>? practice,
    bool persist = false,
  }) async {
    if (_connecting) {
      return;
    }
    _connecting = true;
    _manualDisconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _connectionStatus = 'Connecting...';
    notifyListeners();

    final effectiveToken = token ?? _pairedProfile?.token;
    if (effectiveToken == null || effectiveToken.isEmpty) {
      _connecting = false;
      _connectionStatus = 'Token required. Pair using QR.';
      notifyListeners();
      return;
    }

    final profile = PlayerPairingProfile(
      name: name ?? _pairedProfile?.name ?? 'ChoirPlayer-iPad',
      ip: host,
      port: port,
      token: effectiveToken,
      mode: mode ?? _pairedProfile?.mode,
      sessionId: sessionId ?? _pairedProfile?.sessionId,
      stationId: stationId ?? _pairedProfile?.stationId,
      stationName: stationName ?? _pairedProfile?.stationName,
      lockedPart: lockedPart ?? _pairedProfile?.lockedPart,
      stationPasscode: stationPasscode ?? _pairedProfile?.stationPasscode,
      practice: practice ?? _pairedProfile?.practice,
    );
    _pairedProfile = profile;
    if (persist) {
      await _savePairingProfile(profile);
    }

    try {
      await disconnect(manual: false);
      final socket = await WebSocket.connect(
        'ws://$host:$port/ws',
      ).timeout(const Duration(seconds: 4));
      _socket = socket;
      _authenticated = false;
      _connectionStatus = 'Authorizing...';
      notifyListeners();

      socket.add(
        jsonEncode(<String, dynamic>{
          'type': 'AUTH',
          'token': effectiveToken,
        }),
      );

      _socketSubscription = socket.listen(
        _handleServerMessage,
        onDone: () => _handleDisconnect('Disconnected'),
        onError: (_) => _handleDisconnect('Connection error'),
        cancelOnError: true,
      );
    } catch (_) {
      _connectionStatus = 'Failed to connect';
      _connecting = false;
      _scheduleReconnect();
    } finally {
      _connecting = false;
      notifyListeners();
    }
  }

  void sendCommandEnvelope(
    String command, {
    Map<String, dynamic> args = const <String, dynamic>{},
  }) {
    final socket = _socket;
    if (socket == null || !_authenticated) {
      _connectionStatus = 'Not connected';
      notifyListeners();
      return;
    }
    try {
      socket.add(
        jsonEncode(<String, dynamic>{
          'type': 'COMMAND',
          'command': command,
          'args': args,
        }),
      );
    } catch (_) {
      _handleDisconnect('Failed to send command');
    }
  }

  // Compatibility adapter for older UI call sites.
  void sendCommand(Map<String, dynamic> command) {
    final envelope = _internalCommandToEnvelope(command);
    if (envelope == null) {
      return;
    }
    sendCommandEnvelope(
      envelope.command,
      args: envelope.args,
    );
  }

  Future<void> disconnect({bool manual = true}) async {
    _manualDisconnect = manual;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    final subscription = _socketSubscription;
    _socketSubscription = null;
    if (subscription != null) {
      await subscription.cancel();
    }

    final socket = _socket;
    _socket = null;
    if (socket != null) {
      try {
        await socket.close();
      } catch (_) {}
    }
    _authenticated = false;
    if (manual) {
      _connectionStatus = 'Disconnected';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    unawaited(disconnect());
    super.dispose();
  }

  void _handleServerMessage(dynamic event) {
    if (event is! String) {
      return;
    }
    try {
      final decoded = jsonDecode(event);
      if (decoded is! Map) {
        return;
      }
      final map = decoded.cast<String, dynamic>();
      final type = map['type']?.toString() ?? '';
      switch (type) {
        case 'AUTH_OK':
          _authenticated = true;
          _reconnectTimer?.cancel();
          _reconnectTimer = null;
          _connectionStatus = 'Connected to ${_pairedProfile?.name ?? 'player'}';
          notifyListeners();
          break;
        case 'STATE':
          final payload = map['payload'];
          if (payload is Map) {
            _latestState = payload.cast<String, dynamic>();
            notifyListeners();
          }
          break;
        case 'ERROR':
          final message = map['message']?.toString() ?? 'Server error';
          _connectionStatus = message;
          if (message == 'TOKEN_MISMATCH') {
            _manualDisconnect = true;
          }
          notifyListeners();
          break;
        default:
          return;
      }
    } catch (_) {}
  }

  void _handleDisconnect(String status) {
    _socket = null;
    _socketSubscription = null;
    _authenticated = false;
    _connectionStatus = status;
    notifyListeners();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_manualDisconnect || _pairedProfile == null || _connecting) {
      return;
    }
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      unawaited(connectPaired());
    });
  }

  Future<void> _savePairingProfile(PlayerPairingProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pairedProfilePrefsKey, jsonEncode(profile.toMap()));
  }

  Future<void> _ensureDeviceIdLoaded() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdPrefsKey);
    if (existing != null && existing.isNotEmpty) {
      _deviceId = existing;
      return;
    }
    final created = _generateId('device');
    _deviceId = created;
    await prefs.setString(_deviceIdPrefsKey, created);
  }

  Future<void> _saveDeviceId(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceIdPrefsKey, value);
  }

  String _generateId(String prefix) {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = Random.secure().nextInt(1 << 32);
    return '${prefix}_$now$rand';
  }

  _CommandEnvelope? _internalCommandToEnvelope(Map<String, dynamic> command) {
    final type = command['type']?.toString() ?? '';
    switch (type) {
      case 'PLAY':
        return const _CommandEnvelope('PLAY', <String, dynamic>{});
      case 'PAUSE':
        return const _CommandEnvelope('PAUSE', <String, dynamic>{});
      case 'TOGGLE_PLAY':
        return const _CommandEnvelope('TOGGLE_PLAY', <String, dynamic>{});
      case 'JUMP_TO_MEASURE':
        return _CommandEnvelope('JUMP_TO_MEASURE', <String, dynamic>{
          'measure': command['measure'],
          if (command.containsKey('autoPlay')) 'autoPlay': command['autoPlay'],
        });
      case 'JUMP_RELATIVE':
        return _CommandEnvelope('JUMP_RELATIVE', <String, dynamic>{
          'deltaMeasures': command['deltaMeasures'],
        });
      case 'SET_TEMPO':
        return _CommandEnvelope('SET_TEMPO_PERCENT', <String, dynamic>{
          'percent': command['percent'],
        });
      case 'SET_TEMPO_ADJUST':
        return _CommandEnvelope('ADJUST_TEMPO_PERCENT', <String, dynamic>{
          'deltaPercent': command['delta'],
        });
      case 'SET_LOOP_A':
        return _CommandEnvelope('SET_LOOP_A', <String, dynamic>{
          'measure': command['measure'],
        });
      case 'SET_LOOP_B':
        return _CommandEnvelope('SET_LOOP_B', <String, dynamic>{
          'measure': command['measure'],
        });
      case 'SET_LOOP_RANGE':
        return _CommandEnvelope('SET_LOOP_RANGE', <String, dynamic>{
          'a': command['a'],
          'b': command['b'],
        });
      case 'CLEAR_LOOP':
        return const _CommandEnvelope('CLEAR_LOOP', <String, dynamic>{});
      case 'SET_PART_ENABLED':
        return _CommandEnvelope('SET_PART_ENABLED', <String, dynamic>{
          'part': _internalPartToProtocol(command['part']),
          'enabled': command['enabled'],
        });
      case 'SET_PARTS_ENABLED':
        return _CommandEnvelope('SET_PARTS_ENABLED', <String, dynamic>{
          'partsEnabledSet': command['partsEnabledSet'],
          'pianoEnabled': command['pianoEnabled'],
        });
      case 'SET_MIX_PRESET':
        return _CommandEnvelope('SET_MIX_PRESET', <String, dynamic>{
          'preset': command['preset'],
          'parts': command['parts'],
          'pianoEnabled': command['pianoOn'],
        });
      case 'SET_ALL_PARTS':
        return const _CommandEnvelope('SET_MIX_PRESET', <String, dynamic>{
          'preset': 'ALL',
        });
      case 'PLAY_STARTING_PITCHES':
        return const _CommandEnvelope('PLAY_STARTING_PITCHES', <String, dynamic>{});
      case 'LOOP_ARM_TOGGLE':
        return const _CommandEnvelope('LOOP_ARM_TOGGLE', <String, dynamic>{});
      default:
        return null;
    }
  }

  String _internalPartToProtocol(Object? raw) {
    switch (raw?.toString().toLowerCase()) {
      case 'soprano':
        return 'SOP';
      case 'alto':
        return 'ALTO';
      case 'tenor':
        return 'TENOR';
      case 'bass':
        return 'BASS';
      case 'piano':
        return 'PIANO';
      default:
        return raw?.toString() ?? '';
    }
  }
}

class _CommandEnvelope {
  const _CommandEnvelope(this.command, this.args);

  final String command;
  final Map<String, dynamic> args;
}

