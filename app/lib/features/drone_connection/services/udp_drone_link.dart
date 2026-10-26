import 'dart:async';
import 'dart:convert';
import 'dart:io';

enum DroneLinkState {
  disconnected,
  connecting,
  connected,
  linkLost,
}

class UdpDroneLink {
  UdpDroneLink({
    required this.host,
    this.port = 8765,
    this.localPort = 8766,
  });

  final String host;
  final int port;
  final int localPort;

  RawDatagramSocket? _socket;
  StreamSubscription<RawSocketEvent>? _subscription;
  Timer? _watchdogTimer;
  DateTime? _lastPacketTime;

  final _messages = StreamController<Map<String, dynamic>>.broadcast();
  final _stateController = StreamController<DroneLinkState>.broadcast();

  int _sequence = 0;
  DroneLinkState _state = DroneLinkState.disconnected;

  Stream<Map<String, dynamic>> get messages => _messages.stream;
  Stream<DroneLinkState> get stateStream => _stateController.stream;
  DroneLinkState get state => _state;
  bool get isConnected => _state == DroneLinkState.connected;

  void _setState(DroneLinkState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  Future<void> connect() async {
    if (_socket != null) return;

    _setState(DroneLinkState.connecting);

    try {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        localPort,
      );

      _socket = socket;

      _subscription = socket.listen((event) {
        if (event != RawSocketEvent.read) return;

        Datagram? datagram;
        while ((datagram = socket.receive()) != null) {
          try {
            final decoded = jsonDecode(utf8.decode(datagram!.data));
            if (decoded is! Map<String, dynamic>) continue;
            if (decoded['v'] != 1) continue;

            _lastPacketTime = DateTime.now();

            if (_state != DroneLinkState.connected) {
              _setState(DroneLinkState.connected);
            }

            _messages.add(decoded);
          } on FormatException {
            // Discard malformed packets safely
          }
        }
      });

      // Start 1-second watchdog tick to check for stale telemetry (> 3000ms)
      _watchdogTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_lastPacketTime != null) {
          final elapsed = DateTime.now().difference(_lastPacketTime!).inMilliseconds;
          if (elapsed > 3000 && _state == DroneLinkState.connected) {
            _setState(DroneLinkState.linkLost);
          }
        }
      });

      // Send initial protocol handshake
      _send({
        'v': 1,
        'type': 'hello',
        'client_id': 'pilot-mobile-app',
      });
    } catch (e) {
      _setState(DroneLinkState.disconnected);
      rethrow;
    }
  }

  void _send(Map<String, dynamic> message) {
    final socket = _socket;
    if (socket == null) return;

    final bytes = utf8.encode(jsonEncode({
      ...message,
      'seq': ++_sequence,
    }));

    if (bytes.length > 1200) {
      throw ArgumentError('UDP packet size exceeds 1200 bytes limit.');
    }

    socket.send(bytes, InternetAddress(host), port);
  }

  void ping() => _send({'v': 1, 'type': 'ping'});

  void arm() => _send({'v': 1, 'type': 'arm'});

  void disarm() => _send({'v': 1, 'type': 'disarm'});

  void land() => _send({'v': 1, 'type': 'land'});

  void emergencyStop() => _send({'v': 1, 'type': 'emergency_stop', 'confirm': true});

  void sendSetpoint({
    required double roll,
    required double pitch,
    required double yaw,
    required double thrust,
  }) {
    _send({
      'v': 1,
      'type': 'control_setpoint',
      'roll': roll,
      'pitch': pitch,
      'yaw': yaw,
      'thrust': thrust,
    });
  }

  Future<void> disconnect() async {
    _watchdogTimer?.cancel();
    _watchdogTimer = null;

    await _subscription?.cancel();
    _subscription = null;

    _socket?.close();
    _socket = null;

    _setState(DroneLinkState.disconnected);
  }

  Future<void> dispose() async {
    await disconnect();
    await _messages.close();
    await _stateController.close();
  }
}
