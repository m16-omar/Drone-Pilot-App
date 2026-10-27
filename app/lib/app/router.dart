import 'package:go_router/go_router.dart';

import '../features/dashboard/views/dashboard_screen.dart';
import '../features/flight_3d/views/flight_3d_screen.dart';
import '../features/flight_control/views/flight_control_screen.dart';
import '../features/fleet/views/fleet_screen.dart';
import '../features/fleet/views/server_status_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/flight-3d',
      name: 'flight_3d',
      builder: (context, state) => const Flight3DScreen(),
    ),
    GoRoute(
      path: '/flight-controls',
      name: 'flight_controls',
      builder: (context, state) => const FlightControlScreen(),
    ),
    GoRoute(
      path: '/fleet',
      name: 'fleet',
      builder: (context, state) => const FleetScreen(),
    ),
    GoRoute(
      path: '/server-status',
      name: 'server_status',
      builder: (context, state) => const ServerStatusScreen(),
    ),
  ],
);
