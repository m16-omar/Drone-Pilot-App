import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../drone_connection/services/udp_drone_link.dart';
import '../../telemetry/models/drone_telemetry.dart';
import '../../telemetry/providers/drone_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetryAsync = ref.watch(droneTelemetryProvider);
    final linkStateAsync = ref.watch(droneLinkStateProvider);
    final currentHost = ref.watch(droneHostProvider);

    final linkState = linkStateAsync.value ?? DroneLinkState.disconnected;
    final telemetry = telemetryAsync.value ?? DroneTelemetry.initial;

    return Scaffold(
      backgroundColor: AppColors.jetBlack,
      appBar: AppBar(
        backgroundColor: AppColors.cockpitSlate,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.flight_takeoff, color: AppColors.avionicsBlue),
            SizedBox(width: 8),
            Text(
              'DRONE CONTROL PILOT',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Configure Drone IP ($currentHost)',
            icon: const Icon(Icons.settings_ethernet),
            onPressed: () => _showHostConfigDialog(context, ref, currentHost),
          ),
          IconButton(
            tooltip: 'Reconnect UDP Link',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(droneTelemetryProvider);
              ref.invalidate(droneLinkProvider);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildConnectionStatusBar(context, linkState, telemetry),
          const SizedBox(height: 16),
          _buildPrimaryInstruments(telemetry),
          const SizedBox(height: 16),
          _buildAttitudeCard(telemetry),
          const SizedBox(height: 16),
          _buildQuickActionButtons(context, ref, telemetry, linkState),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusBar(
    BuildContext context,
    DroneLinkState state,
    DroneTelemetry telemetry,
  ) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (state) {
      case DroneLinkState.connected:
        statusColor = AppColors.telemetryGreen;
        statusText = 'LINK ACTIVE (100%)';
        statusIcon = Icons.wifi;
        break;
      case DroneLinkState.connecting:
        statusColor = AppColors.alertAmber;
        statusText = 'NEGOTIATING HANDSHAKE...';
        statusIcon = Icons.wifi_find;
        break;
      case DroneLinkState.linkLost:
        statusColor = AppColors.emergencyRed;
        statusText = 'LINK LOST (>3000ms)';
        statusIcon = Icons.wifi_off;
        break;
      case DroneLinkState.disconnected:
        statusColor = Colors.grey;
        statusText = 'OFFLINE';
        statusIcon = Icons.portable_wifi_off;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cockpitSlate,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  'Device: ${telemetry.deviceId} · Mode: ${telemetry.flightMode}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
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
            child: Text(
              telemetry.isArmed ? 'ARMED' : 'DISARMED',
              style: TextStyle(
                color: telemetry.isArmed ? AppColors.emergencyRed : AppColors.telemetryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryInstruments(DroneTelemetry telemetry) {
    Color batteryColor;
    if (telemetry.batteryPercent > 30) {
      batteryColor = AppColors.telemetryGreen;
    } else if (telemetry.batteryPercent > 15) {
      batteryColor = AppColors.alertAmber;
    } else {
      batteryColor = AppColors.emergencyRed;
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        _InstrumentTile(
          label: 'BATTERY',
          value: '${telemetry.batteryPercent.toStringAsFixed(1)}%',
          subtext: 'Estimated Reserve',
          icon: Icons.battery_charging_full,
          accentColor: batteryColor,
        ),
        _InstrumentTile(
          label: 'ALTITUDE',
          value: '${telemetry.altitudeMeters.toStringAsFixed(1)} m',
          subtext: 'Barometric Height',
          icon: Icons.height,
          accentColor: AppColors.avionicsBlue,
        ),
        _InstrumentTile(
          label: 'AIRSPEED',
          value: '${telemetry.speedMps.toStringAsFixed(1)} m/s',
          subtext: 'Ground Velocity',
          icon: Icons.speed,
          accentColor: Colors.cyanAccent,
        ),
        _InstrumentTile(
          label: 'GPS NAVIGATION',
          value: telemetry.hasGpsFix ? '3D LOCK' : 'NO FIX',
          subtext: telemetry.hasGpsFix ? 'Satellites Connected' : 'IMU Mode Only',
          icon: Icons.gps_fixed,
          accentColor: telemetry.hasGpsFix ? AppColors.telemetryGreen : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildAttitudeCard(DroneTelemetry telemetry) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cockpitSlate,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.explore, color: AppColors.avionicsBlue, size: 18),
              SizedBox(width: 8),
              Text(
                'ATTITUDE ESTIMATION',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AttitudeMetric(
                label: 'ROLL',
                value: '${telemetry.rollDeg.toStringAsFixed(1)}°',
                color: Colors.lightBlueAccent,
              ),
              _AttitudeMetric(
                label: 'PITCH',
                value: '${telemetry.pitchDeg.toStringAsFixed(1)}°',
                color: Colors.orangeAccent,
              ),
              _AttitudeMetric(
                label: 'YAW / HEADING',
                value: '${telemetry.yawDeg.toStringAsFixed(1)}°',
                color: Colors.purpleAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons(
    BuildContext context,
    WidgetRef ref,
    DroneTelemetry telemetry,
    DroneLinkState linkState,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.avionicsBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.gamepad),
            label: const Text(
              'OPEN COCKPIT & FLIGHT CONTROLS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            onPressed: () => context.push('/flight-controls'),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.textMuted),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.cloud_sync, size: 18),
                label: const Text('CLOUD FLEET'),
                onPressed: () => context.push('/fleet'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.textMuted),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.monitor_heart, size: 18),
                label: const Text('API HEALTH'),
                onPressed: () => context.push('/server-status'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showHostConfigDialog(BuildContext context, WidgetRef ref, String currentHost) {
    final controller = TextEditingController(text: currentHost);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cockpitSlate,
        title: const Text('Drone UDP Endpoint IP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configure the IP address of the drone or simulator:\n'
              '• 127.0.0.1 (macOS Simulator)\n'
              '• 10.0.2.2 (Android Emulator)\n'
              '• 192.168.4.1 (ESP32 SoftAP default)',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Host IP Address',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('Apply & Reconnect'),
            onPressed: () {
              ref.read(droneHostProvider.notifier).updateHost(controller.text.trim());
              ref.invalidate(droneLinkProvider);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _InstrumentTile extends StatelessWidget {
  const _InstrumentTile({
    required this.label,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final String value;
  final String subtext;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cockpitSlate,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, color: accentColor, size: 20),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtext,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _AttitudeMetric extends StatelessWidget {
  const _AttitudeMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
