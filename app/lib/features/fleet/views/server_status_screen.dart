import 'package:drone_control_pilot_client/drone_control_pilot_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/serverpod_service.dart';

class ServerStatusScreen extends ConsumerStatefulWidget {
  const ServerStatusScreen({super.key});

  @override
  ConsumerState<ServerStatusScreen> createState() => _ServerStatusScreenState();
}

class _ServerStatusScreenState extends ConsumerState<ServerStatusScreen> {
  SystemStatus? _status;
  bool _loading = true;
  String? _error;
  int? _latencyMs;

  @override
  void initState() {
    super.initState();
    _checkServer();
  }

  Future<void> _checkServer() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final client = ref.read(serverpodClientProvider);
      final status = await client.system.status();
      stopwatch.stop();
      setState(() {
        _status = status;
        _latencyMs = stopwatch.elapsedMilliseconds;
        _loading = false;
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.jetBlack,
      appBar: AppBar(
        backgroundColor: AppColors.cockpitSlate,
        title: const Text('SERVERPOD BACKEND STATUS'),
        actions: [
          IconButton(
            tooltip: 'Ping Healthcheck',
            icon: const Icon(Icons.refresh),
            onPressed: _checkServer,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, color: AppColors.alertAmber, size: 54),
                        const SizedBox(height: 16),
                        const Text(
                          'Serverpod Backend Unreachable',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error: $_error\n\n'
                          'To start the local Serverpod backend:\n'
                          'cd drone_control_pilot_server && dart bin/main.dart',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry Ping'),
                          onPressed: _checkServer,
                        ),
                      ],
                    ),
                  )
                : ListView(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cockpitSlate,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.telemetryGreen.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.telemetryGreen, size: 36),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _status?.service ?? 'Serverpod API',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    'Status: ${_status?.status.toUpperCase()} · Mode: ${_status?.mode}',
                                    style: const TextStyle(color: AppColors.telemetryGreen, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Chip(
                              label: Text('${_latencyMs ?? '--'} ms'),
                              backgroundColor: AppColors.cardSurface,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailTile('Service Name', _status?.service ?? '--'),
                      _buildDetailTile('API Version', _status?.version ?? '--'),
                      _buildDetailTile('Runtime Mode', _status?.mode ?? '--'),
                      _buildDetailTile('RPC Latency', '${_latencyMs ?? '--'} ms'),
                    ],
                  ),
      ),
    );
  }

  Widget _buildDetailTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cockpitSlate,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
