import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/tactile_components.dart';
import '../../drone_connection/services/udp_drone_link.dart';
import '../../telemetry/models/drone_telemetry.dart';
import '../../telemetry/providers/drone_providers.dart';
import '../render/flight_3d_painter.dart';
import '../render/renderer3d.dart';

enum CameraMode {
  chase,
  fpv,
  orbit,
}

enum FlightTimeOfDay {
  day,
  sunset,
  night,
}

class Flight3DScreen extends ConsumerStatefulWidget {
  const Flight3DScreen({super.key});

  @override
  ConsumerState<Flight3DScreen> createState() => _Flight3DScreenState();
}

class _Flight3DScreenState extends ConsumerState<Flight3DScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final Renderer3D _renderer = Renderer3D();
  final Camera _camera = Camera();

  // Drone local state (synthesized or driven by telemetry)
  double _droneX = 0.0;
  double _droneY = 0.22; // On landing pad
  double _droneZ = 0.0;
  double _roll = 0.0;
  double _pitch = 0.0;
  double _yaw = 0.0;
  double _propAngle = 0.0;

  // Virtual control setpoints
  double _throttle = 0.0;
  double _yawInput = 0.0;
  double _pitchInput = 0.0;
  double _rollInput = 0.0;

  // Joystick pointers
  Offset _leftStick = Offset.zero;
  Offset _rightStick = Offset.zero;

  CameraMode _cameraMode = CameraMode.chase;
  FlightTimeOfDay _timeOfDay = FlightTimeOfDay.day;

  // Orbit camera drag angles
  double _orbitYaw = 0.0;
  double _orbitPitch = -0.32;
  final double _orbitDistance = 5.2;

  Duration _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();
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

    final telemetry = ref.read(droneTelemetryProvider).value;
    final isArmed = telemetry?.isArmed ?? (_throttle > 0.05);

    setState(() {
      // 1. Propeller spinning
      if (isArmed) {
        final speed = 25.0 + (_throttle * 40.0);
        _propAngle = (_propAngle + speed * dt) % (math.pi * 2);
      }

      // 2. Physics & Kinematics (driven by telemetry if available, otherwise virtual controls)
      if (telemetry != null && telemetry.rollDeg.abs() + telemetry.pitchDeg.abs() > 0.01) {
        _roll = telemetry.rollDeg * math.pi / 180.0;
        _pitch = telemetry.pitchDeg * math.pi / 180.0;
        _yaw = telemetry.yawDeg * math.pi / 180.0;
        _droneY = math.max(0.22, telemetry.altitudeMeters);
      } else {
        // Local interactive simulator mode when flying manually
        _roll = _rollInput * 0.35;
        _pitch = -_pitchInput * 0.35;
        _yaw += _yawInput * 1.5 * dt;

        if (_throttle > 0.1) {
          final targetAlt = 0.22 + (_throttle * 6.0);
          _droneY += (targetAlt - _droneY) * 2.5 * dt;
          final forwardSpeed = -_pitchInput * 4.0;
          final lateralSpeed = _rollInput * 4.0;
          _droneX += (lateralSpeed * math.cos(_yaw) + forwardSpeed * math.sin(_yaw)) * dt;
          _droneZ += (forwardSpeed * math.cos(_yaw) - lateralSpeed * math.sin(_yaw)) * dt;
        } else {
          _droneY = math.max(0.22, _droneY - 1.8 * dt);
        }
      }

      // 3. Update Camera based on active mode
      switch (_cameraMode) {
        case CameraMode.chase:
          const dist = 4.2;
          const height = 1.8;
          _camera.x = _droneX - math.sin(_yaw) * dist;
          _camera.z = _droneZ - math.cos(_yaw) * dist;
          _camera.y = _droneY + height;
          _camera.yaw = _yaw;
          _camera.pitch = -0.22;
          break;
        case CameraMode.fpv:
          _camera.x = _droneX + math.sin(_yaw) * 0.35;
          _camera.y = _droneY + 0.12;
          _camera.z = _droneZ + math.cos(_yaw) * 0.35;
          _camera.yaw = _yaw;
          _camera.pitch = _pitch;
          break;
        case CameraMode.orbit:
          _camera.x = _droneX + math.sin(_orbitYaw) * math.cos(_orbitPitch) * _orbitDistance;
          _camera.z = _droneZ + math.cos(_orbitYaw) * math.cos(_orbitPitch) * _orbitDistance;
          _camera.y = _droneY - math.sin(_orbitPitch) * _orbitDistance;
          _camera.yaw = _orbitYaw + math.pi;
          _camera.pitch = _orbitPitch;
          break;
      }
    });

    // Send UDP setpoints to link
    final link = ref.read(droneLinkProvider);
    link.sendSetpoint(
      roll: _rollInput,
      pitch: _pitchInput,
      yaw: _yawInput,
      thrust: _throttle,
    );
  }

  Lighting get _currentLighting {
    switch (_timeOfDay) {
      case FlightTimeOfDay.day:
        return Lighting.day;
      case FlightTimeOfDay.sunset:
        return Lighting.sunset;
      case FlightTimeOfDay.night:
        return Lighting.night;
    }
  }

  @override
  Widget build(BuildContext context) {
    final telemetryAsync = ref.watch(droneTelemetryProvider);
    final linkStateAsync = ref.watch(droneLinkStateProvider);
    final telemetry = telemetryAsync.value ?? DroneTelemetry.initial;
    final linkState = linkStateAsync.value ?? DroneLinkState.disconnected;

    final isArmed = telemetry.isArmed || (_throttle > 0.05);

    return Scaffold(
      backgroundColor: AppColors.jetBlack,
      body: Stack(
        children: [
          // 1. 3D Viewport with Gesture detection for Orbit Camera
          Positioned.fill(
            child: GestureDetector(
              onPanUpdate: (details) {
                if (_cameraMode == CameraMode.orbit) {
                  setState(() {
                    _orbitYaw -= details.delta.dx * 0.008;
                    _orbitPitch = (_orbitPitch - details.delta.dy * 0.008).clamp(-1.2, 0.2);
                  });
                }
              },
              child: CustomPaint(
                painter: Flight3DPainter(
                  renderer: _renderer,
                  camera: _camera,
                  lighting: _currentLighting,
                  droneX: _droneX,
                  droneY: _droneY,
                  droneZ: _droneZ,
                  roll: _roll,
                  pitch: _pitch,
                  yaw: _yaw,
                  propAngle: _propAngle,
                  isArmed: isArmed,
                  drawEnvironment: true,
                  drawHudOverlay: _cameraMode == CameraMode.fpv,
                ),
              ),
            ),
          ),

          // 2. Top Status HUD Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button to Dashboard
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.8),
                      ),
                      onPressed: () => context.pop(),
                    ),
                    // Live Stats Pills (Lagos Life style)
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            StatPill(
                              icon: Icons.battery_charging_full,
                              label: 'BATT',
                              value: '${telemetry.batteryPercent.toStringAsFixed(0)}%',
                              color: telemetry.batteryPercent < 20
                                  ? AppColors.emergencyRed
                                  : AppColors.telemetryGreen,
                            ),
                            const SizedBox(width: 8),
                            StatPill(
                              icon: Icons.height,
                              label: 'ALT',
                              value: '${_droneY.toStringAsFixed(1)}m',
                              color: AppColors.avionicsBlue,
                            ),
                            const SizedBox(width: 8),
                            StatPill(
                              icon: Icons.speed,
                              label: 'SPD',
                              value: '${telemetry.speedMps.toStringAsFixed(1)}m/s',
                              color: const Color(0xFF38BDF8),
                            ),
                            const SizedBox(width: 8),
                            StatPill(
                              icon: Icons.wifi,
                              label: 'LINK',
                              value: linkState == DroneLinkState.connected ? 'ONLINE' : 'SEARCHING',
                              color: linkState == DroneLinkState.connected
                                  ? AppColors.telemetryGreen
                                  : AppColors.alertAmber,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Camera Mode & Environment Quick Switcher
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Camera buttons
                    GlassHudPanel(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      borderRadius: 99,
                      child: Row(
                        children: [
                          _buildModeChip('CHASE', CameraMode.chase),
                          _buildModeChip('FPV', CameraMode.fpv),
                          _buildModeChip('ORBIT', CameraMode.orbit),
                        ],
                      ),
                    ),
                    // Lighting buttons
                    GlassHudPanel(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      borderRadius: 99,
                      child: Row(
                        children: [
                          _buildLightingChip(Icons.wb_sunny, FlightTimeOfDay.day),
                          _buildLightingChip(Icons.wb_twilight, FlightTimeOfDay.sunset),
                          _buildLightingChip(Icons.nights_stay, FlightTimeOfDay.night),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. Virtual Dual Joysticks (Mode 2)
          Positioned(
            left: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
            child: _buildJoystick(
              isThrottle: true,
              label: 'THROTTLE / YAW',
              onChanged: (offset) {
                setState(() {
                  _leftStick = offset;
                  // Left Stick: Y is throttle (0..1), X is yaw (-1..1)
                  _throttle = ((-offset.dy).clamp(0.0, 1.0));
                  _yawInput = offset.dx;
                });
              },
            ),
          ),

          Positioned(
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
            child: _buildJoystick(
              isThrottle: false,
              label: 'PITCH / ROLL',
              onChanged: (offset) {
                setState(() {
                  _rightStick = offset;
                  // Right Stick: Y is pitch (-1..1), X is roll (-1..1)
                  _pitchInput = -offset.dy;
                  _rollInput = offset.dx;
                });
              },
            ),
          ),

          // 4. Center Bottom Flight Safety Badges
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 0,
            right: 0,
            child: Center(
              child: GlassHudPanel(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                borderRadius: 24,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isArmed
                            ? AppColors.emergencyRed
                            : AppColors.telemetryGreen,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      icon: Icon(isArmed ? Icons.power_settings_new : Icons.play_arrow),
                      label: Text(
                        isArmed ? 'DISARM' : 'ARM MOTORS',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: () {
                        final link = ref.read(droneLinkProvider);
                        if (isArmed) {
                          link.emergencyStop();
                          setState(() {
                            _throttle = 0.0;
                          });
                        } else {
                          link.arm();
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF38BDF8)),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      icon: const Icon(Icons.flight_land, color: Color(0xFF38BDF8)),
                      label: const Text('AUTO-LAND', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        ref.read(droneLinkProvider).land();
                        setState(() {
                          _throttle = 0.0;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(String label, CameraMode mode) {
    final active = _cameraMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _cameraMode = mode),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.avionicsBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildLightingChip(IconData icon, FlightTimeOfDay time) {
    final active = _timeOfDay == time;
    return GestureDetector(
      onTap: () => setState(() => _timeOfDay = time),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF59E0B) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 14,
          color: active ? Colors.white : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildJoystick({
    required bool isThrottle,
    required String label,
    required ValueChanged<Offset> onChanged,
  }) {
    const double size = 120.0;
    const double radius = size / 2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onPanUpdate: (details) {
            final local = details.localPosition - const Offset(radius, radius);
            final len = local.distance;
            final normalized = len > radius ? (local / len) : (local / radius);
            onChanged(normalized);
          },
          onPanEnd: (_) {
            if (!isThrottle) {
              // Right stick springs back to center
              onChanged(Offset.zero);
            }
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0F172A).withValues(alpha: 0.65),
              border: Border.all(color: const Color(0x4038BDF8), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Crosshair axes
                Container(width: size - 20, height: 1, color: const Color(0x1FFFFFFF)),
                Container(width: 1, height: size - 20, color: const Color(0x1FFFFFFF)),
                // Thumb knob
                Transform.translate(
                  offset: isThrottle
                      ? Offset(_leftStick.dx * radius * 0.75, _leftStick.dy * radius * 0.75)
                      : Offset(_rightStick.dx * radius * 0.75, _rightStick.dy * radius * 0.75),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.avionicsBlue,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.avionicsBlue.withValues(alpha: 0.6),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
