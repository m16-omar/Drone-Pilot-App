import 'package:drone_control_pilot_client/drone_control_pilot_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/serverpod_service.dart';

class FleetScreen extends ConsumerStatefulWidget {
  const FleetScreen({super.key});

  @override
  ConsumerState<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends ConsumerState<FleetScreen> {
  List<DroneDevice> _drones = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDrones();
  }

  Future<void> _fetchDrones() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = ref.read(serverpodClientProvider);
      final drones = await client.drone.listDrones();
      setState(() {
        _drones = drones;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _registerNewDroneDialog() async {
    final nameController = TextEditingController();
    final idController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cockpitSlate,
        title: const Text('Register New Drone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                labelText: 'Hardware Device ID (e.g. ESP32-4F2A)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Drone Name (e.g. Field Alpha)',
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
            child: const Text('Register'),
            onPressed: () async {
              if (idController.text.isNotEmpty && nameController.text.isNotEmpty) {
                Navigator.of(ctx).pop();
                try {
                  final client = ref.read(serverpodClientProvider);
                  await client.drone.registerDrone(
                    idController.text.trim(),
                    nameController.text.trim(),
                    'DIY-ESP32-Custom',
                    'v1.0.0',
                    ['telemetry', 'arm', 'waypoint'],
                  );
                  await _fetchDrones();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to register: $e')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.jetBlack,
      appBar: AppBar(
        backgroundColor: AppColors.cockpitSlate,
        title: const Text('SERVERPOD CLOUD FLEET REGISTRY'),
        actions: [
          IconButton(
            tooltip: 'Refresh Fleet',
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDrones,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.avionicsBlue,
        tooltip: 'Register Drone',
        onPressed: _registerNewDroneDialog,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, color: AppColors.alertAmber, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'Serverpod Backend Offline or Unreachable',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error: $_error\n\n'
                          'Note: Flight control works 100% offline via local UDP. '
                          'To enable cloud fleet sync, start the Serverpod server with:\n'
                          'serverpod start',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry Serverpod Connection'),
                          onPressed: _fetchDrones,
                        ),
                      ],
                    ),
                  ),
                )
              : _drones.isEmpty
                  ? const Center(
                      child: Text('No drones registered yet. Tap + to register one.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _drones.length,
                      itemBuilder: (context, index) {
                        final drone = _drones[index];
                        return Card(
                          color: AppColors.cockpitSlate,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: AppColors.cardSurface),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.cardSurface,
                              child: Icon(Icons.flight, color: AppColors.avionicsBlue),
                            ),
                            title: Text(
                              drone.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'ID: ${drone.deviceId} · Model: ${drone.model}\nFirmware: ${drone.firmwareVersion}',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                            trailing: Chip(
                              label: Text('${drone.capabilities.length} Cap'),
                              backgroundColor: AppColors.cardSurface,
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
