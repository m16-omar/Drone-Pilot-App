import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drone_control_pilot_flutter/core/theme/app_theme.dart';
import 'package:drone_control_pilot_flutter/core/theme/theme_provider.dart';
import 'package:drone_control_pilot_flutter/features/ai_assistant/models/ai_message.dart';
import 'package:drone_control_pilot_flutter/features/ai_assistant/services/ai_copilot_service.dart';
import 'package:drone_control_pilot_flutter/features/drone_connection/services/udp_drone_link.dart';
import 'package:drone_control_pilot_flutter/features/flight_control/views/flight_control_screen.dart';
import 'package:drone_control_pilot_flutter/features/telemetry/models/drone_telemetry.dart';

void main() {
  group('Theme System Tests', () {
    test('themeModeProvider starts at dark mode and toggles correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.dark);

      container.read(themeModeProvider.notifier).toggleTheme();
      expect(container.read(themeModeProvider), ThemeMode.light);

      container.read(themeModeProvider.notifier).toggleTheme();
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('AppTheme creates high-contrast light and dark themes', () {
      final darkTheme = AppTheme.dark();
      final lightTheme = AppTheme.light();

      expect(darkTheme.brightness, Brightness.dark);
      expect(lightTheme.brightness, Brightness.light);
      expect(darkTheme.scaffoldBackgroundColor, const Color(0xFF0B1120));
      expect(lightTheme.scaffoldBackgroundColor, const Color(0xFFF1F5F9));
    });
  });

  group('AI Copilot Service Flight Reasoning Tests', () {
    const service = AiCopilotService();
    const mockTelemetry = DroneTelemetry(
      version: 1,
      sequence: 10,
      deviceId: 'SIM-DRONE',
      timestampMs: 1793050000,
      isArmed: true,
      batteryPercent: 88.0,
      rollDeg: 0.0,
      pitchDeg: 0.0,
      yawDeg: 90.0,
      altitudeMeters: 10.5,
      speedMps: 2.1,
      hasGpsFix: true,
      linkQualityPercent: 100,
      flightMode: 'POS_HOLD',
    );

    test('Emergency command triggers instant emergency stop action', () {
      final res = service.processQuery(
        query: 'Emergency stop! Kill motors now!',
        telemetry: mockTelemetry,
        linkState: DroneLinkState.connected,
      );

      expect(res.action, isNotNull);
      expect(res.action!.type, FlightActionType.emergencyStop);
    });

    test('Takeoff command suggests safe takeoff sequence', () {
      final disarmedTelemetry = mockTelemetry.copyWith(isArmed: false, altitudeMeters: 0.0);
      final res = service.processQuery(
        query: 'Take off to 3 meters',
        telemetry: disarmedTelemetry,
        linkState: DroneLinkState.connected,
      );

      expect(res.action, isNotNull);
      expect(res.action!.type, FlightActionType.takeOff);
      expect(res.text.contains('Takeoff'), isTrue);
    });

    test('Land command triggers controlled descent action', () {
      final res = service.processQuery(
        query: 'Initiate auto landing procedure',
        telemetry: mockTelemetry,
        linkState: DroneLinkState.connected,
      );

      expect(res.action, isNotNull);
      expect(res.action!.type, FlightActionType.land);
    });

    test('Hover hold command triggers position & altitude stabilization', () {
      final res = service.processQuery(
        query: 'Hover in place and hold position',
        telemetry: mockTelemetry,
        linkState: DroneLinkState.connected,
      );

      expect(res.action, isNotNull);
      expect(res.action!.type, FlightActionType.hoverHold);
    });

    test('Diagnostics check returns comprehensive preflight assessment', () {
      final res = service.processQuery(
        query: 'Run pre-flight diagnostics check',
        telemetry: mockTelemetry,
        linkState: DroneLinkState.connected,
      );

      expect(res.text.contains('Battery Reserve: 🟢 88.0%'), isTrue);
      expect(res.text.contains('3D GPS Fix'), isTrue);
    });

    test('Unconnected drone prompts connection warning', () {
      final res = service.processQuery(
        query: 'Take off',
        telemetry: DroneTelemetry.initial,
        linkState: DroneLinkState.disconnected,
      );

      expect(res.action, isNull);
      expect(res.text.toLowerCase().contains('disconnected'), isTrue);
    });
  });

  group('FlightControlScreen Widget Tests', () {
    testWidgets('Renders Mode 2 controls, telemetry ribbon, and action bars', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlightControlScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('COCKPIT FLIGHT CONTROLS (MODE 2)'), findsOneWidget);
      expect(find.text('LEFT STICK (THROTTLE / YAW)'), findsOneWidget);
      expect(find.text('RIGHT STICK (PITCH / ROLL)'), findsOneWidget);
      expect(find.text('CENTER TRIM'), findsOneWidget);
      expect(find.text('HOVER HOLD'), findsOneWidget);
      expect(find.text('AI COPILOT'), findsOneWidget);
      expect(find.text('AUTO LAND'), findsOneWidget);
      expect(find.text('EMERGENCY CUTOFF'), findsOneWidget);
      expect(find.text('ALT'), findsOneWidget);
      expect(find.text('BATT'), findsOneWidget);
    });
  });
}
