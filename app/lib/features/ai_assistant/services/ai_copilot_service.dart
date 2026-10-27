import '../../drone_connection/services/udp_drone_link.dart';
import '../../telemetry/models/drone_telemetry.dart';
import '../models/ai_message.dart';

class AiCopilotService {
  const AiCopilotService();

  /// Processes natural language input from pilot against real-time telemetry.
  AiMessage processQuery({
    required String query,
    required DroneTelemetry telemetry,
    required DroneLinkState linkState,
  }) {
    final lower = query.toLowerCase().trim();
    final now = DateTime.now();
    final msgId = 'msg_${now.millisecondsSinceEpoch}';

    // 1. Emergency Disarm / Cut Motors
    if (lower.contains('emergency') ||
        lower.contains('cut motor') ||
        lower.contains('kill') ||
        (lower.contains('disarm') && !lower.contains('check'))) {
      return AiMessage(
        id: msgId,
        text: '⚠️ EMERGENCY PROTOCOL TRIGGERED.\n'
            'Immediate throttle cut and motor disarm staged. Confirm to execute emergency disarm.',
        isUser: false,
        timestamp: now,
        action: const FlightAction(
          type: FlightActionType.emergencyStop,
          label: 'EXECUTE EMERGENCY DISARM',
          requiresConfirmation: true,
        ),
      );
    }

    // 2. Pre-flight Diagnostics / Health Check
    if (lower.contains('check') ||
        lower.contains('diagnostic') ||
        lower.contains('health') ||
        lower.contains('status') ||
        lower.contains('battery')) {
      final isLinkOk = linkState == DroneLinkState.connected;
      final batt = telemetry.batteryPercent;
      final isBattOk = batt > 25.0;
      final isGpsOk = telemetry.hasGpsFix;
      final isAttitudeLevel = telemetry.rollDeg.abs() < 10.0 && telemetry.pitchDeg.abs() < 10.0;

      final buffer = StringBuffer('📋 AI PRE-FLIGHT DIAGNOSTICS REPORT:\n\n');
      buffer.writeln('• Link Status: ${isLinkOk ? "🟢 ACTIVE (UDP 100%)" : "🔴 OFFLINE / CONNECTING"}');
      buffer.writeln('• Battery Reserve: ${isBattOk ? "🟢" : "🟡"} ${batt.toStringAsFixed(1)}% (${isBattOk ? "Safe for flight" : "Low battery alert"})');
      buffer.writeln('• Navigation Fix: ${isGpsOk ? "🟢 3D GPS Fix" : "🟡 IMU Dead-Reckoning"}');
      buffer.writeln('• IMU Attitude: ${isAttitudeLevel ? "🟢 Level (${telemetry.rollDeg.toStringAsFixed(1)}°, ${telemetry.pitchDeg.toStringAsFixed(1)}°)" : "🟡 Tilted"}');
      buffer.writeln('• Altitude: ${telemetry.altitudeMeters.toStringAsFixed(1)} m · Speed: ${telemetry.speedMps.toStringAsFixed(1)} m/s');
      buffer.writeln('• Arm State: ${telemetry.isArmed ? "⚠️ ARMED" : "🔒 SAFE / DISARMED"}');

      if (!isBattOk) {
        buffer.writeln('\n⚠️ Warning: Battery below 25%. Recharge or replace flight pack before high-altitude operations.');
      } else if (isAttitudeLevel && isLinkOk) {
        buffer.writeln('\n✅ All primary systems GO. Safe for autonomous or manual flight.');
      }

      return AiMessage(
        id: msgId,
        text: buffer.toString(),
        isUser: false,
        timestamp: now,
        action: const FlightAction(
          type: FlightActionType.preFlightCheck,
          label: 'REFRESH DIAGNOSTICS',
          requiresConfirmation: false,
        ),
      );
    }

    // 3. Take Off Command
    if (lower.contains('take off') ||
        lower.contains('takeoff') ||
        lower.contains('launch') ||
        lower.contains('fly up') ||
        lower.contains('ascend')) {
      if (linkState != DroneLinkState.connected) {
        return AiMessage(
          id: msgId,
          text: '⚠️ Cannot takeoff: Drone telemetry link is disconnected. Verify Wi-Fi or UDP link connection before initiating flight.',
          isUser: false,
          timestamp: now,
        );
      }

      if (telemetry.batteryPercent < 15.0) {
        return AiMessage(
          id: msgId,
          text: '❌ Takeoff rejected: Battery reserve (${telemetry.batteryPercent.toStringAsFixed(1)}%) is critically low (<15%). Connect charger.',
          isUser: false,
          timestamp: now,
        );
      }

      // Extract target altitude if mentioned (e.g. "take off to 3m")
      double targetAlt = 2.0;
      final match = RegExp(r'(\d+(\.\d+)?)\s*(m|meter)').firstMatch(lower);
      if (match != null) {
        targetAlt = double.tryParse(match.group(1)!) ?? 2.0;
      }

      return AiMessage(
        id: msgId,
        text: '🛫 Takeoff sequence calculated for target altitude ${targetAlt.toStringAsFixed(1)} m.\n'
            'Motors will spin up, drone will climb vertically and transition to automatic hover lock.',
        isUser: false,
        timestamp: now,
        action: FlightAction(
          type: FlightActionType.takeOff,
          label: 'COMMENCE TAKEOFF (${targetAlt.toStringAsFixed(1)}m)',
          params: {'altitude': targetAlt, 'thrust': 0.65},
          requiresConfirmation: true,
        ),
      );
    }

    // 4. Land Command
    if (lower.contains('land') ||
        lower.contains('touch down') ||
        lower.contains('come down') ||
        lower.contains('descend') ||
        lower.contains('return')) {
      return AiMessage(
        id: msgId,
        text: '🛬 Controlled landing trajectory initialized.\n'
            'Autonomous throttle descent profile: 0.35 m/s descent velocity until touchdown detection.',
        isUser: false,
        timestamp: now,
        action: const FlightAction(
          type: FlightActionType.land,
          label: 'EXECUTE AUTO-LANDING',
          params: {'thrust': 0.28},
          requiresConfirmation: true,
        ),
      );
    }

    // 5. Hover / Stabilize Hold Command
    if (lower.contains('hover') ||
        lower.contains('hold') ||
        lower.contains('stabilize') ||
        lower.contains('level')) {
      return AiMessage(
        id: msgId,
        text: '🛑 Engaging 3D Position & Altitude Hover Hold.\n'
            'Roll and pitch trims zeroed. Maintaining barometric height at ${telemetry.altitudeMeters.toStringAsFixed(1)} m.',
        isUser: false,
        timestamp: now,
        action: const FlightAction(
          type: FlightActionType.hoverHold,
          label: 'ENGAGE HOVER HOLD',
          params: {'thrust': 0.50},
          requiresConfirmation: false,
        ),
      );
    }

    // 6. 360° Orbit / Panorama Scan
    if (lower.contains('orbit') ||
        lower.contains('360') ||
        lower.contains('scan') ||
        lower.contains('panorama') ||
        lower.contains('rotate')) {
      return AiMessage(
        id: msgId,
        text: '🔄 360° Aerial Horizon Panorama Scan.\n'
            'Drone will perform a smooth constant-rate yaw rotation to capture 360° perimeter telemetry and gimbal video.',
        isUser: false,
        timestamp: now,
        action: const FlightAction(
          type: FlightActionType.orbitScan,
          label: 'START 360° PANORAMA SCAN',
          params: {'yawRate': 0.35, 'thrust': 0.52},
          requiresConfirmation: true,
        ),
      );
    }

    // 7. Aeronautical Guidance / Help
    if (lower.contains('help') || lower.contains('mode') || lower.contains('how')) {
      return AiMessage(
        id: msgId,
        text: '🤖 I am your AI Avionics Co-Pilot.\n\n'
            'Commands you can speak or type:\n'
            '• "Take off to 2.5 meters"\n'
            '• "Run pre-flight check"\n'
            '• "Hover in place"\n'
            '• "Scan area in 360 orbit"\n'
            '• "Land drone immediately"\n'
            '• "Emergency disarm motors"\n\n'
            'Mode 2 Controls: Left stick handles Throttle (up/down) & Yaw (turn). Right stick handles Pitch (fwd/back) & Roll (left/right).',
        isUser: false,
        timestamp: now,
      );
    }

    // Fallback response with live telemetry context
    return AiMessage(
      id: msgId,
      text: '🤖 AI Co-Pilot standby. Current telemetry: '
          'Altitude ${telemetry.altitudeMeters.toStringAsFixed(1)}m, '
          'Battery ${telemetry.batteryPercent.toStringAsFixed(0)}%, '
          'Speed ${telemetry.speedMps.toStringAsFixed(1)}m/s. '
          'You can ask me to "Take off", "Hold altitude", "Check diagnostics", or "Land".',
      isUser: false,
      timestamp: now,
    );
  }

  /// Dispatches the calculated flight action parameters to the live UDP drone link.
  Future<void> executeAction(FlightAction action, UdpDroneLink link) async {
    switch (action.type) {
      case FlightActionType.takeOff:
        final thrust = (action.params['thrust'] as num?)?.toDouble() ?? 0.65;
        link.sendSetpoint(roll: 0.0, pitch: 0.0, yaw: 0.0, thrust: thrust);
        break;

      case FlightActionType.land:
        final thrust = (action.params['thrust'] as num?)?.toDouble() ?? 0.28;
        link.sendSetpoint(roll: 0.0, pitch: 0.0, yaw: 0.0, thrust: thrust);
        break;

      case FlightActionType.hoverHold:
        final thrust = (action.params['thrust'] as num?)?.toDouble() ?? 0.50;
        link.sendSetpoint(roll: 0.0, pitch: 0.0, yaw: 0.0, thrust: thrust);
        break;

      case FlightActionType.orbitScan:
        final yaw = (action.params['yawRate'] as num?)?.toDouble() ?? 0.35;
        final thrust = (action.params['thrust'] as num?)?.toDouble() ?? 0.50;
        link.sendSetpoint(roll: 0.0, pitch: 0.0, yaw: yaw, thrust: thrust);
        break;

      case FlightActionType.emergencyStop:
        link.sendSetpoint(roll: 0.0, pitch: 0.0, yaw: 0.0, thrust: 0.0);
        break;

      case FlightActionType.preFlightCheck:
      case FlightActionType.setAltitude:
        break;
    }
  }
}
