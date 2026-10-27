import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../ai_assistant/views/ai_assistant_sheet.dart';
import '../../telemetry/models/drone_telemetry.dart';
import '../../telemetry/providers/drone_providers.dart';

class FlightControlScreen extends ConsumerStatefulWidget {
  const FlightControlScreen({super.key});

  @override
  ConsumerState<FlightControlScreen> createState() => _FlightControlScreenState();
}

class _FlightControlScreenState extends ConsumerState<FlightControlScreen> {
  double _throttle = 0.0;
  double _yaw = 0.0;
  double _pitch = 0.0;
  double _roll = 0.0;
  bool _sliderArmed = false;

  void _dispatchSetpoints() {
    final link = ref.read(droneLinkProvider);
    link.sendSetpoint(
      roll: _roll,
      pitch: _pitch,
      yaw: _yaw,
      thrust: _throttle,
    );
  }

  void _centerSticks() {
    setState(() {
      _roll = 0.0;
      _pitch = 0.0;
      _yaw = 0.0;
    });
    _dispatchSetpoints();
  }

  void _hoverHold() {
    setState(() {
      _throttle = 0.5;
      _roll = 0.0;
      _pitch = 0.0;
      _yaw = 0.0;
    });
    _dispatchSetpoints();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hover Hold setpoint engaged (Thrust: 50%, Attitude: 0.0°)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final telemetryAsync = ref.watch(droneTelemetryProvider);
    final link = ref.watch(droneLinkProvider);
    final telemetry = telemetryAsync.value ?? DroneTelemetry.initial;
    final isDark = context.isDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'COCKPIT FLIGHT CONTROLS (MODE 2)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
        ),
        actions: [
          IconButton(
            tooltip: isDark ? 'Switch to Light Mood' : 'Switch to Dark Mood',
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: isDark ? const Color(0xFFFACC15) : const Color(0xFF0284C7),
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          IconButton(
            tooltip: 'AI Flight Assistant',
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF38BDF8)),
            onPressed: () => AiAssistantSheet.show(context),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: telemetry.isArmed
                  ? AppColors.emergencyRed.withValues(alpha: 0.2)
                  : AppColors.telemetryGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: telemetry.isArmed ? AppColors.emergencyRed : AppColors.telemetryGreen,
              ),
            ),
            child: Center(
              child: Text(
                telemetry.isArmed ? 'ARMED' : 'DISARMED',
                style: TextStyle(
                  color: telemetry.isArmed ? AppColors.emergencyRed : AppColors.telemetryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              // Real-time Flight Dynamics Ribbon
              _buildFlightRibbon(context, telemetry),
              const SizedBox(height: 10),

              // Safety Warning Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.alertAmber.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.alertAmber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Keep hands clear of propellers during bench testing. Watchdog auto-lands on signal drop.',
                        style: TextStyle(color: context.textMuted, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Virtual Sticks Container (Left: Throttle/Yaw, Right: Pitch/Roll)
              Expanded(
                child: Row(
                  children: [
                    // Left Stick: Throttle (Vertical) & Yaw (Horizontal)
                    Expanded(
                      child: _buildStickCard(
                        context: context,
                        title: 'LEFT STICK (THROTTLE / YAW)',
                        vLabel: 'Throttle: ${(_throttle * 100).toInt()}%',
                        hLabel: 'Yaw: ${(_yaw * 100).toInt()}%',
                        vValue: _throttle,
                        hValue: _yaw,
                        vColor: AppColors.avionicsBlue,
                        hColor: Colors.cyan,
                        onChangedV: (val) {
                          setState(() => _throttle = val);
                          _dispatchSetpoints();
                        },
                        onChangedH: (val) {
                          setState(() => _yaw = val);
                          _dispatchSetpoints();
                        },
                        vMin: 0.0,
                        vMax: 1.0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Right Stick: Pitch (Vertical) & Roll (Horizontal)
                    Expanded(
                      child: _buildStickCard(
                        context: context,
                        title: 'RIGHT STICK (PITCH / ROLL)',
                        vLabel: 'Pitch: ${(_pitch * 100).toInt()}%',
                        hLabel: 'Roll: ${(_roll * 100).toInt()}%',
                        vValue: _pitch,
                        hValue: _roll,
                        vColor: Colors.orangeAccent,
                        hColor: Colors.purpleAccent,
                        onChangedV: (val) {
                          setState(() => _pitch = val);
                          _dispatchSetpoints();
                        },
                        onChangedH: (val) {
                          setState(() => _roll = val);
                          _dispatchSetpoints();
                        },
                        vMin: -1.0,
                        vMax: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Trim & Assistance Quick Bar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.textPrimary,
                        side: BorderSide(color: context.cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.center_focus_strong, size: 16),
                      label: const Text('CENTER TRIM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: _centerSticks,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF38BDF8),
                        side: const BorderSide(color: Color(0xFF38BDF8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.flight, size: 16),
                      label: const Text('HOVER HOLD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: _hoverHold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('AI COPILOT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () => AiAssistantSheet.show(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Bottom Safety Command Bar (Arm Switch, Land, Emergency Stop)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Switch(
                          value: _sliderArmed,
                          activeThumbColor: AppColors.emergencyRed,
                          onChanged: (val) {
                            setState(() => _sliderArmed = val);
                            if (val) {
                              link.arm();
                            } else {
                              link.disarm();
                            }
                          },
                        ),
                        Text(
                          _sliderArmed ? 'MOTORS ARMED' : 'ARM SAFETY LOCK',
                          style: TextStyle(
                            color: _sliderArmed ? AppColors.emergencyRed : context.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.alertAmber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.flight_land, size: 16),
                      label: const Text('AUTO LAND', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () {
                        link.land();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Auto-land sequence dispatched')),
                        );
                      },
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emergencyRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.stop_circle, size: 16),
                      label: const Text('EMERGENCY CUTOFF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () {
                        setState(() {
                          _throttle = 0.0;
                          _pitch = 0.0;
                          _roll = 0.0;
                          _yaw = 0.0;
                          _sliderArmed = false;
                        });
                        link.emergencyStop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('EMERGENCY STOP TRIGGERED: Motors cut!'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlightRibbon(BuildContext context, DroneTelemetry telemetry) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ribbonItem(
            context,
            'ALT',
            '${telemetry.altitudeMeters.toStringAsFixed(1)}m',
            Icons.height,
            AppColors.avionicsBlue,
          ),
          _ribbonItem(
            context,
            'SPD',
            '${telemetry.speedMps.toStringAsFixed(1)}m/s',
            Icons.speed,
            Colors.cyan,
          ),
          _ribbonItem(
            context,
            'BATT',
            '${telemetry.batteryPercent.toStringAsFixed(0)}%',
            Icons.battery_charging_full,
            telemetry.batteryPercent > 25 ? AppColors.telemetryGreen : AppColors.alertAmber,
          ),
          _ribbonItem(
            context,
            'GPS',
            telemetry.hasGpsFix ? '3D FIX' : 'NO FIX',
            Icons.gps_fixed,
            telemetry.hasGpsFix ? AppColors.telemetryGreen : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _ribbonItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 9, color: context.textMuted, fontWeight: FontWeight.bold)),
            Text(value, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildStickCard({
    required BuildContext context,
    required String title,
    required String vLabel,
    required String hLabel,
    required double vValue,
    required double hValue,
    required Color vColor,
    required Color hColor,
    required ValueChanged<double> onChangedV,
    required ValueChanged<double> onChangedH,
    required double vMin,
    required double vMax,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: vColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
          Divider(color: context.cardBorder, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(vLabel, style: TextStyle(fontSize: 11, color: context.textMuted)),
              Text('${((vValue - vMin) / (vMax - vMin) * 100).toInt()}%',
                  style: TextStyle(fontSize: 11, color: vColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: vValue,
            min: vMin,
            max: vMax,
            activeColor: vColor,
            onChanged: onChangedV,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(hLabel, style: TextStyle(fontSize: 11, color: context.textMuted)),
              Text('${(hValue * 100).toInt()}%',
                  style: TextStyle(fontSize: 11, color: hColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: hValue,
            min: -1.0,
            max: 1.0,
            activeColor: hColor,
            onChanged: onChangedH,
          ),
        ],
      ),
    );
  }
}
