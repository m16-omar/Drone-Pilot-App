import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class SystemEndpoint extends Endpoint {
  Future<SystemStatus> status(Session session) async {
    return SystemStatus(
      service: 'Drone Control Pilot API',
      status: 'healthy',
      version: '1.0.0',
      mode: 'development',
    );
  }
}
