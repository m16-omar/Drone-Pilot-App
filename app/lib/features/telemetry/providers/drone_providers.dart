import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../drone_connection/services/udp_drone_link.dart';
import '../models/drone_telemetry.dart';

class DroneHostNotifier extends Notifier<String> {
  @override
  String build() => '127.0.0.1';

  void updateHost(String newHost) => state = newHost;
}

final droneHostProvider = NotifierProvider<DroneHostNotifier, String>(DroneHostNotifier.new);

class DronePortNotifier extends Notifier<int> {
  @override
  int build() => 8765;

  void updatePort(int newPort) => state = newPort;
}

final dronePortProvider = NotifierProvider<DronePortNotifier, int>(DronePortNotifier.new);

final droneLinkProvider = Provider<UdpDroneLink>((ref) {
  final host = ref.watch(droneHostProvider);
  final port = ref.watch(dronePortProvider);

  final link = UdpDroneLink(host: host, port: port);

  ref.onDispose(() {
    unawaited(link.dispose());
  });

  return link;
});

final droneLinkStateProvider = StreamProvider<DroneLinkState>((ref) async* {
  final link = ref.watch(droneLinkProvider);
  yield link.state;
  yield* link.stateStream;
});

final droneTelemetryProvider = StreamProvider<DroneTelemetry>((ref) async* {
  final link = ref.watch(droneLinkProvider);

  await link.connect();

  await for (final message in link.messages) {
    if (message['type'] == 'telemetry') {
      yield DroneTelemetry.fromJson(message);
    }
  }
});
