import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    final telemetryAsync = ref.watch(droneTelemetryProvider);
    final link = ref.watch(droneLinkProvider);
    final telemetry = telemetryAsync.value ?? DroneTelemetry.initial;

    return Scaffold(
      backgroundColor: AppColors.jetBlack,
      appBar: AppBar(
        backgroundColor: AppColors.cockpitSlate,
        title: const Text('COCKPIT FLIGHT CONTROLS (MODE 2)'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
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
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Safety Warning Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.alertAmber.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.alertAmber, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Keep hands clear of propellers during bench testing. Link watchdog will auto-land if connection drops.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Virtual Sticks Container (Left: Throttle/Yaw, Right: Pitch/Roll)
              Expanded(
                child: Row(
                  children: [
                    // Left Stick: Throttle (Vertical) & Yaw (Horizontal)
                    Expanded(
                      child: _buildStickCard(
                        title: 'LEFT STICK (THROTTLE / YAW)',
                        vLabel: 'Throttle: ${(_throttle * 100).toInt()}%',
                        hLabel: 'Yaw: ${(_yaw * 100).toInt()}%',
                        vValue: _throttle,
                        hValue: _yaw,
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
                    const SizedBox(width: 16),
                    // Right Stick: Pitch (Vertical) & Roll (Horizontal)
                    Expanded(
                      child: _buildStickCard(
                        title: 'RIGHT STICK (PITCH / ROLL)',
                        vLabel: 'Pitch: ${(_pitch * 100).toInt()}%',
                        hLabel: 'Roll: ${(_roll * 100).toInt()}%',
                        vValue: _pitch,
                        hValue: _roll,
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
              const SizedBox(height: 16),

              // Bottom Safety Command Bar (Arm Switch, Land, Emergency Stop)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cockpitSlate,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
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
                                color: _sliderArmed ? AppColors.emergencyRed : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.alertAmber,
                            foregroundColor: Colors.black,
                          ),
                          icon: const Icon(Icons.flight_land, size: 18),
                          label: const Text('AUTO LAND', style: TextStyle(fontWeight: FontWeight.bold)),
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
                          ),
                          icon: const Icon(Icons.stop_circle, size: 18),
                          label: const Text('EMERGENCY CUTOFF', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStickCard({
    required String title,
    required String vLabel,
    required String hLabel,
    required double vValue,
    required double hValue,
    required ValueChanged<double> onChangedV,
    required ValueChanged<double> onChangedH,
    required double vMin,
    required double vMax,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cockpitSlate,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.avionicsBlue,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const Divider(color: AppColors.cardSurface),
          Text(vLabel, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          Slider(
            value: vValue,
            min: vMin,
            max: vMax,
            activeColor: AppColors.avionicsBlue,
            onChanged: onChangedV,
          ),
          Text(hLabel, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          Slider(
            value: hValue,
            min: -1.0,
            max: 1.0,
            activeColor: Colors.cyanAccent,
            onChanged: onChangedH,
          ),
        ],
      ),
    );
  }
}
