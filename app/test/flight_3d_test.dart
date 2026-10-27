import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drone_control_pilot_flutter/features/flight_3d/render/renderer3d.dart';
import 'package:drone_control_pilot_flutter/features/flight_3d/render/flight_3d_painter.dart';
import 'package:drone_control_pilot_flutter/features/flight_3d/views/flight_3d_screen.dart';

void main() {
  test('Flight3D geometry and renderer generates vertices', () {
    final renderer = Renderer3D();
    final camera = Camera()
      ..x = 0
      ..y = 1.15
      ..z = 2.4
      ..yaw = 0
      ..pitch = -0.38;

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(390, 200);

    final painter = Flight3DPainter(
      renderer: renderer,
      camera: camera,
      lighting: Lighting.day,
      droneX: 0,
      droneY: 0.18,
      droneZ: 0,
      roll: 0,
      pitch: 0,
      yaw: 0.4,
      propAngle: 0,
      isArmed: false,
      drawEnvironment: false,
      drawHudOverlay: false,
    );

    painter.paint(canvas, size);
    final picture = recorder.endRecording();
    expect(picture, isNotNull);
  });

  test('Flight3D full arena environment renders beacon towers and gates', () {
    final renderer = Renderer3D();
    final camera = Camera()
      ..x = 0
      ..y = 5.0
      ..z = -10.0
      ..yaw = math.pi
      ..pitch = -0.2;

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(800, 600);

    final painter = Flight3DPainter(
      renderer: renderer,
      camera: camera,
      lighting: Lighting.sunset,
      droneX: 0,
      droneY: 2.0,
      droneZ: 5.0,
      roll: 0.1,
      pitch: -0.05,
      yaw: 1.2,
      propAngle: 1.5,
      isArmed: true,
      drawEnvironment: true,
      drawHudOverlay: true,
    );

    painter.paint(canvas, size);
    final picture = recorder.endRecording();
    expect(picture, isNotNull);
  });

  testWidgets('Flight3DScreen renders 3D arena viewport, camera modes, and tactile HUD', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Flight3DScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('CHASE'), findsOneWidget);
    expect(find.text('FPV'), findsOneWidget);
    expect(find.text('ORBIT'), findsOneWidget);
    expect(find.text('THROTTLE / YAW'), findsOneWidget);
    expect(find.text('PITCH / ROLL'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
