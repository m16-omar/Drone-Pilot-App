import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'drone_3d_geometry.dart';
import 'renderer3d.dart';

/// CustomPainter rendering the real-time 3D Drone & Airfield scene on Flutter Canvas.
class Flight3DPainter extends CustomPainter {
  Flight3DPainter({
    required this.renderer,
    required this.camera,
    required this.lighting,
    required this.droneX,
    required this.droneY,
    required this.droneZ,
    required this.roll,
    required this.pitch,
    required this.yaw,
    required this.propAngle,
    required this.isArmed,
    this.drawEnvironment = true,
    this.drawHudOverlay = false,
  });

  final Renderer3D renderer;
  final Camera camera;
  final Lighting lighting;
  final double droneX, droneY, droneZ;
  final double roll, pitch, yaw; // radians
  final double propAngle;
  final bool isArmed;
  final bool drawEnvironment;
  final bool drawHudOverlay;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Build Ground Polygons
    final isLightPad = lighting == Lighting.day;
    final ground = drawEnvironment
        ? Drone3DGeometry.buildEnvironmentGround(
            droneX: droneX,
            droneY: droneY,
            droneZ: droneZ,
          )
        : <GroundPoly>[
            GroundPoly.circle(
              0, 0, 1.2,
              isLightPad ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B),
              y: 0,
              sides: 16,
            ),
            ...GroundPoly.ring(
              0, 0, 1.02, 1.12,
              isLightPad ? const Color(0xFF0284C7) : const Color(0xFF38BDF8),
              y: 0.01,
              sides: 16,
            ),
          ];

    // 2. Build 3D Drone parts
    final droneParts = Drone3DGeometry.buildDrone(
      x: droneX,
      y: droneY,
      z: droneZ,
      roll: roll,
      pitch: pitch,
      yaw: yaw,
      propAngle: propAngle,
      isArmed: isArmed,
    );

    // 3. Build Static Environment Solids
    final environmentParts = drawEnvironment ? Drone3DGeometry.buildEnvironmentSolids() : <Part>[];

    final allParts = [...environmentParts, ...droneParts];

    // 4. Render 3D Frame
    renderer.render(
      canvas,
      size,
      camera,
      lighting,
      ground,
      allParts,
      drawSky: drawEnvironment,
    );

    // 5. Optional FPV HUD Crosshair / Pitch Ladder overlay
    if (drawHudOverlay) {
      _drawCockpitHud(canvas, size);
    }
  }

  void _drawCockpitHud(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final hudPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.75)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Central reticle crosshair
    canvas.drawLine(Offset(cx - 24, cy), Offset(cx - 8, cy), hudPaint);
    canvas.drawLine(Offset(cx + 8, cy), Offset(cx + 24, cy), hudPaint);
    canvas.drawLine(Offset(cx, cy - 24), Offset(cx, cy - 8), hudPaint);
    canvas.drawLine(Offset(cx, cy + 8), Offset(cx, cy + 24), hudPaint);
    canvas.drawCircle(Offset(cx, cy), 3, hudPaint..style = PaintingStyle.fill);

    // 3D Pitch / Horizon line tilted by roll
    hudPaint.style = PaintingStyle.stroke;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-roll);

    // Horizon line
    final horizonPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.45)
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(-80, 0), const Offset(-28, 0), horizonPaint);
    canvas.drawLine(const Offset(28, 0), const Offset(80, 0), horizonPaint);

    // Pitch ladder rungs (+10°, -10°)
    final pitchPx = (pitch * 180 / math.pi) * 3.0;
    canvas.drawLine(Offset(-40, -30 + pitchPx), Offset(40, -30 + pitchPx), hudPaint);
    canvas.drawLine(Offset(-40, 30 + pitchPx), Offset(40, 30 + pitchPx), hudPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant Flight3DPainter oldDelegate) => true;
}
