import 'package:drone_control_pilot_client/drone_control_pilot_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

import 'app/app.dart';
import 'core/services/serverpod_service.dart';

export 'core/services/serverpod_service.dart' show client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Determine Serverpod server URL (defaults to localhost:8080)
  final serverUrl = await getServerUrl();

  globalServerpodClient = Client(serverUrl)
    ..connectivityMonitor = FlutterConnectivityMonitor()
    ..authSessionManager = FlutterAuthSessionManager();

  try {
    globalServerpodClient.auth.initialize();
  } catch (_) {
    // Ignore if running completely offline
  }

  runApp(
    const ProviderScope(
      child: DronePilotApp(),
    ),
  );
}
