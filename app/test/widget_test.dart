import 'package:flutter_test/flutter_test.dart';
import 'package:drone_control_pilot_flutter/features/telemetry/models/drone_telemetry.dart';
import 'package:drone_control_pilot_flutter/features/drone_connection/services/udp_drone_link.dart';

void main() {
  group('DroneTelemetry Model Tests', () {
    test('initial model has expected default values', () {
      const initial = DroneTelemetry.initial;
      expect(initial.isArmed, isFalse);
      expect(initial.altitudeMeters, 0.0);
      expect(initial.batteryPercent, 0.0);
      expect(initial.flightMode, 'DISCONNECTED');
    });

    test('fromJson parses standard telemetry datagram correctly', () {
      final json = {
        'v': 1,
        'seq': 42,
        'device_id': 'SIM-001',
        'timestamp_ms': 1793050000000,
        'armed': true,
        'battery_percent': 85.5,
        'roll_deg': 2.1,
        'pitch_deg': -1.4,
        'yaw_deg': 180.0,
        'altitude_m': 12.5,
        'speed_mps': 3.2,
        'gps_fix': true,
        'link_quality_percent': 100,
        'flight_mode': 'ALT_HOLD',
      };

      final telemetry = DroneTelemetry.fromJson(json);

      expect(telemetry.version, 1);
      expect(telemetry.sequence, 42);
      expect(telemetry.deviceId, 'SIM-001');
      expect(telemetry.isArmed, isTrue);
      expect(telemetry.batteryPercent, 85.5);
      expect(telemetry.rollDeg, 2.1);
      expect(telemetry.pitchDeg, -1.4);
      expect(telemetry.yawDeg, 180.0);
      expect(telemetry.altitudeMeters, 12.5);
      expect(telemetry.speedMps, 3.2);
      expect(telemetry.hasGpsFix, isTrue);
      expect(telemetry.flightMode, 'ALT_HOLD');
    });
  });

  group('UdpDroneLink Service Tests', () {
    test('initial state is disconnected', () {
      final link = UdpDroneLink(host: '127.0.0.1', port: 8765, localPort: 8799);
      expect(link.state, DroneLinkState.disconnected);
      expect(link.isConnected, isFalse);
    });
  });
}
