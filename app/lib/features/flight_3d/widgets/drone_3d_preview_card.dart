import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/tactile_components.dart';
import '../../telemetry/models/drone_telemetry.dart';
import '../render/flight_3d_painter.dart';
import '../render/renderer3d.dart';

/// Interactive 3D Drone Preview card for the primary dashboard.
class Drone3DPreviewCard extends StatefulWidget {
  const Drone3DPreviewCard({
    super.key,
    required this.telemetry,
    required this.isArmed,
  });

  final DroneTelemetry telemetry;
  final bool isArmed;

  @override
  State<Drone3DPreviewCard> createState() => _Drone3DPreviewCardState();
}

class _Drone3DPreviewCardState extends State<Drone3DPreviewCard>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final Renderer3D _renderer = Renderer3D();
  final Camera _camera = Camera();

  double _turntableYaw = 0.4;
  double _propAngle = 0.0;
  Duration _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();
    _camera.x = 0;
    _camera.y = 1.15;
    _camera.z = 2.4;
    _camera.yaw = 0;
    _camera.pitch = -0.38;

    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }
    final dt = (elapsed - _lastTick).inMicroseconds / 1000000.0;
    _lastTick = elapsed;

    setState(() {
      _turntableYaw = (_turntableYaw + 0.35 * dt) % (math.pi * 2);
      if (widget.isArmed) {
        _propAngle = (_propAngle + 35.0 * dt) % (math.pi * 2);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final rollRad = widget.telemetry.rollDeg * math.pi / 180.0;
    final pitchRad = widget.telemetry.pitchDeg * math.pi / 180.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBorder = isDark
        ? const Color(0xFF0284C7).withValues(alpha: 0.4)
        : const Color(0xFF0284C7).withValues(alpha: 0.25);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return TactileCard(
      padding: EdgeInsets.zero,
      color: cardBg,
      borderColor: cardBorder,
      onTap: () => context.push('/flight-3d'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.view_in_ar, color: Color(0xFF38BDF8), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '3D DRONE AVIONICS VIEW',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.1,
                        color: titleColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'LIVE 60FPS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF38BDF8),
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3D Viewport canvas
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(double.infinity, 190),
                  painter: Flight3DPainter(
                    renderer: _renderer,
                    camera: _camera,
                    lighting: Lighting.day,
                    droneX: 0,
                    droneY: 0.18,
                    droneZ: 0,
                    roll: rollRad,
                    pitch: pitchRad,
                    yaw: _turntableYaw,
                    propAngle: _propAngle,
                    isArmed: widget.isArmed,
                    drawEnvironment: false,
                    drawHudOverlay: false,
                  ),
                ),

                // Corner telemetry badge
                Positioned(
                  bottom: 8,
                  left: 12,
                  child: Row(
                    children: [
                      StatPill(
                        label: 'ROLL',
                        value: '${widget.telemetry.rollDeg.toStringAsFixed(1)}°',
                        color: const Color(0xFF38BDF8),
                      ),
                      const SizedBox(width: 6),
                      StatPill(
                        label: 'PITCH',
                        value: '${widget.telemetry.pitchDeg.toStringAsFixed(1)}°',
                        color: AppColors.alertAmber,
                      ),
                    ],
                  ),
                ),

                // 3D Arena Button
                Positioned(
                  bottom: 8,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.avionicsBlue,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.avionicsBlue.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '3D ARENA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 14, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
