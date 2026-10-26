import 'package:drone_control_pilot_client/drone_control_pilot_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

late final Client globalServerpodClient;

Client get client => globalServerpodClient;

final serverpodClientProvider = Provider<Client>((ref) {
  return globalServerpodClient;
});
