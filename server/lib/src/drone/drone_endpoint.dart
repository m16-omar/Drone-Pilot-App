import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class DroneEndpoint extends Endpoint {
  static final List<DroneDevice> _registeredDrones = [
    DroneDevice(
      deviceId: 'SIM-001',
      name: 'Simulator Quadcopter',
      model: 'ESP32-DIY-SIM',
      firmwareVersion: 'simulator-1.0',
      capabilities: ['telemetry', 'arm_simulated', 'mission_simulation'],
      registeredAt: DateTime.now(),
    ),
  ];

  Future<List<DroneDevice>> listDrones(Session session) async {
    return _registeredDrones;
  }

  Future<DroneDevice> registerDrone(
    Session session,
    String deviceId,
    String name,
    String model,
    String firmwareVersion,
    List<String> capabilities,
  ) async {
    final drone = DroneDevice(
      deviceId: deviceId,
      name: name,
      model: model,
      firmwareVersion: firmwareVersion,
      capabilities: capabilities,
      registeredAt: DateTime.now(),
    );
    _registeredDrones.add(drone);
    return drone;
  }
}
