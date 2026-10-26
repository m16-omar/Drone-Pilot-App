import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'router.dart';

class DronePilotApp extends StatelessWidget {
  const DronePilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Drone Control Pilot',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.jetBlack,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.avionicsBlue,
          brightness: Brightness.dark,
        ),
        cardTheme: const CardThemeData(
          color: AppColors.cockpitSlate,
          elevation: 2,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.cockpitSlate,
          elevation: 0,
        ),
      ),
    );
  }
}
