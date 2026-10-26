import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class FlightSessionEndpoint extends Endpoint {
  static final List<FlightSession> _sessions = [];

  Future<List<FlightSession>> listSessions(Session session) async {
    return _sessions;
  }

  Future<FlightSession> recordSession(
    Session session,
    FlightSession flightSession,
  ) async {
    _sessions.add(flightSession);
    return flightSession;
  }
}
