import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

typedef CommandHandler = void Function(Map<String, dynamic> command);
typedef StateSnapshotBuilder = Map<String, dynamic> Function();

class LocalPlayerServer {
  LocalPlayerServer({
    this.commandPort = 45454,
    this.announcePort = 45455,
  });

  final int commandPort;
  final int announcePort;

  ServerSocket? _commandServer;
  RawDatagramSocket? _announceSocket;
  Timer? _announceTimer;
  final List<Socket> _clients = [];

  CommandHandler? _commandHandler;
  StateSnapshotBuilder? _stateSnapshotBuilder;

  bool get isRunning => _commandServer != null;

  Future<void> start({
    required CommandHandler onCommand,
    required StateSnapshotBuilder stateBuilder,
  }) async {
    if (isRunning) {
      return;
    }
    _commandHandler = onCommand;
    _stateSnapshotBuilder = stateBuilder;

    _commandServer = await ServerSocket.bind(
      InternetAddress.anyIPv4,
      commandPort,
      shared: true,
    );
    _commandServer!.listen(
      _handleClient,
      onError: (_) {},
      onDone: () {},
    );

    _announceSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      0,
      reuseAddress: true,
      reusePort: true,
    );
    _announceSocket!.broadcastEnabled = true;
    _announceTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _broadcastAnnouncement(),
    );
    _broadcastAnnouncement();
  }

  void broadcastState() {
    if (_clients.isEmpty) {
      return;
    }
    final builder = _stateSnapshotBuilder;
    if (builder == null) {
      return;
    }
    final line = '${jsonEncode(builder())}\n';
    final disconnected = <Socket>[];
    for (final client in _clients) {
      try {
        client.write(line);
      } catch (_) {
        disconnected.add(client);
      }
    }
    for (final dead in disconnected) {
      _removeClient(dead);
    }
  }

  Future<void> stop() async {
    _announceTimer?.cancel();
    _announceTimer = null;
    _announceSocket?.close();
    _announceSocket = null;

    final clients = _clients.toList();
    _clients.clear();
    for (final client in clients) {
      try {
        await client.close();
      } catch (_) {}
    }

    final server = _commandServer;
    _commandServer = null;
    if (server != null) {
      await server.close();
    }
  }

  void _handleClient(Socket socket) {
    socket.setOption(SocketOption.tcpNoDelay, true);
    _clients.add(socket);
    _sendStateTo(socket);

    socket
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) => _handleClientLine(line),
          onError: (_) => _removeClient(socket),
          onDone: () => _removeClient(socket),
          cancelOnError: true,
        );
  }

  void _handleClientLine(String line) {
    final handler = _commandHandler;
    if (handler == null || line.trim().isEmpty) {
      return;
    }
    try {
      final decoded = jsonDecode(line);
      if (decoded is Map<String, dynamic>) {
        handler(decoded);
        broadcastState();
      } else if (decoded is Map) {
        handler(decoded.cast<String, dynamic>());
        broadcastState();
      }
    } catch (_) {
      // Ignore malformed payloads in MVP mode.
    }
  }

  void _sendStateTo(Socket socket) {
    final builder = _stateSnapshotBuilder;
    if (builder == null) {
      return;
    }
    try {
      socket.write('${jsonEncode(builder())}\n');
    } catch (_) {}
  }

  void _removeClient(Socket socket) {
    _clients.remove(socket);
    try {
      socket.destroy();
    } catch (_) {}
  }

  void _broadcastAnnouncement() {
    final socket = _announceSocket;
    if (socket == null) {
      return;
    }
    final payload = jsonEncode({
      'type': 'PLAYER_ANNOUNCE',
      'port': commandPort,
      'app': 'choir_rehearsal_mvp',
    });
    final bytes = utf8.encode(payload);
    socket.send(bytes, InternetAddress('255.255.255.255'), announcePort);
  }
}

class DiscoveredPlayer {
  DiscoveredPlayer({
    required this.host,
    required this.port,
    required this.lastSeen,
  });

  final String host;
  final int port;
  DateTime lastSeen;
}

class RemoteClient extends ChangeNotifier {
  RemoteClient({this.announcePort = 45455});

  final int announcePort;

  RawDatagramSocket? _discoverySocket;
  Timer? _staleCleanupTimer;

  final Map<String, DiscoveredPlayer> _discoveredPlayersByHost = {};
  Socket? _commandSocket;
  StreamSubscription<String>? _commandSubscription;
  Map<String, dynamic>? _latestState;

  String? _connectedHost;
  int? _connectedPort;
  String? _connectionStatus;
  bool _connecting = false;

  List<DiscoveredPlayer> get discoveredPlayers =>
      _discoveredPlayersByHost.values.toList()
        ..sort((a, b) => a.host.compareTo(b.host));

  Map<String, dynamic>? get latestState => _latestState;
  String? get connectedHost => _connectedHost;
  int? get connectedPort => _connectedPort;
  String? get connectionStatus => _connectionStatus;
  bool get isConnected => _commandSocket != null;
  bool get isConnecting => _connecting;

  Future<void> startDiscovery() async {
    if (_discoverySocket != null) {
      return;
    }
    _discoverySocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      announcePort,
      reuseAddress: true,
      reusePort: true,
    );
    _discoverySocket!.listen((event) {
      if (event != RawSocketEvent.read) {
        return;
      }
      final datagram = _discoverySocket!.receive();
      if (datagram == null) {
        return;
      }
      _handleAnnouncement(
        sourceHost: datagram.address.address,
        payload: datagram.data,
      );
    });

    _staleCleanupTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _dropStalePlayers(),
    );
  }

  Future<void> connect({
    required String host,
    required int port,
  }) async {
    if (_connecting) {
      return;
    }
    _connecting = true;
    _connectionStatus = 'Connecting...';
    notifyListeners();
    try {
      await disconnect();
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 3),
      );
      socket.setOption(SocketOption.tcpNoDelay, true);
      _commandSocket = socket;
      _connectedHost = host;
      _connectedPort = port;
      _connectionStatus = 'Connected to $host:$port';

      _commandSubscription = socket
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            _handleServerLine,
            onError: (_) => _handleDisconnect('Connection error'),
            onDone: () => _handleDisconnect('Disconnected'),
            cancelOnError: true,
          );
    } catch (error) {
      _connectionStatus = 'Failed to connect';
    } finally {
      _connecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    final subscription = _commandSubscription;
    _commandSubscription = null;
    if (subscription != null) {
      await subscription.cancel();
    }
    final socket = _commandSocket;
    _commandSocket = null;
    if (socket != null) {
      try {
        await socket.close();
      } catch (_) {}
      try {
        socket.destroy();
      } catch (_) {}
    }
    _connectedHost = null;
    _connectedPort = null;
    notifyListeners();
  }

  void sendCommand(Map<String, dynamic> command) {
    final socket = _commandSocket;
    if (socket == null) {
      return;
    }
    try {
      socket.write('${jsonEncode(command)}\n');
    } catch (_) {
      _handleDisconnect('Failed to send');
    }
  }

  @override
  void dispose() {
    _staleCleanupTimer?.cancel();
    _discoverySocket?.close();
    _discoverySocket = null;
    _commandSubscription?.cancel();
    _commandSubscription = null;
    try {
      _commandSocket?.destroy();
    } catch (_) {}
    _commandSocket = null;
    super.dispose();
  }

  void _handleAnnouncement({
    required String sourceHost,
    required List<int> payload,
  }) {
    try {
      final decoded = jsonDecode(utf8.decode(payload));
      if (decoded is! Map) {
        return;
      }
      final map = decoded.cast<String, dynamic>();
      if (map['type'] != 'PLAYER_ANNOUNCE') {
        return;
      }
      final port = map['port'];
      if (port is! int) {
        return;
      }
      final existing = _discoveredPlayersByHost[sourceHost];
      if (existing == null) {
        _discoveredPlayersByHost[sourceHost] = DiscoveredPlayer(
          host: sourceHost,
          port: port,
          lastSeen: DateTime.now(),
        );
      } else {
        existing.lastSeen = DateTime.now();
      }
      notifyListeners();
    } catch (_) {
      // Ignore malformed broadcasts.
    }
  }

  void _handleServerLine(String line) {
    try {
      final decoded = jsonDecode(line);
      if (decoded is Map) {
        _latestState = decoded.cast<String, dynamic>();
        notifyListeners();
      }
    } catch (_) {
      // Ignore malformed state payload.
    }
  }

  void _dropStalePlayers() {
    if (_discoveredPlayersByHost.isEmpty) {
      return;
    }
    final now = DateTime.now();
    final staleHosts = _discoveredPlayersByHost.entries
        .where((entry) => now.difference(entry.value.lastSeen).inSeconds > 5)
        .map((entry) => entry.key)
        .toList();
    for (final host in staleHosts) {
      _discoveredPlayersByHost.remove(host);
    }
    if (staleHosts.isNotEmpty) {
      notifyListeners();
    }
  }

  void _handleDisconnect(String status) {
    _connectionStatus = status;
    _commandSocket = null;
    _commandSubscription = null;
    _connectedHost = null;
    _connectedPort = null;
    notifyListeners();
  }
}

