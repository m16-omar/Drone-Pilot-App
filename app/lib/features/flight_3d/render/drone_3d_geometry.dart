import 'dart:math' as math;
import 'dart:ui';

import 'renderer3d.dart';

/// Precomputed 3D meshes and parts for the Drone Control Pilot platform.
class Drone3DGeometry {
  Drone3DGeometry._();

  // Color Palette
  static const Color carbonBlack = Color(0xFF1E293B);
  static const Color carbonArm = Color(0xFF0F172A);
  static const Color motorTitanium = Color(0xFF475569);
  static const Color canopyGlass = Color(0xFF0284C7);
  static const Color propNeonGreen = Color(0xFF10B981);
  static const Color propNeonRed = Color(0xFFEF4444);
  static const Color propCarbon = Color(0xFF334155);
  static const Color navLedGreen = Color(0xFF22C55E);
  static const Color navLedRed = Color(0xFFEF4444);
  static const Color navLedWhite = Color(0xFFF8FAFC);
  static const Color runwayDark = Color(0xFF1E293B);
  static const Color tarmacLine = Color(0xFFF59E0B);
  static const Color gateRingNeon = Color(0xFF38BDF8);

  // Meshes
  static final Mesh fuselageBody = Mesh.box(
    0.42, 0.16, 0.60,
    carbonBlack,
    top: const Color(0xFF334155),
    front: canopyGlass,
  );

  static final Mesh canopyPod = Mesh.box(
    0.28, 0.10, 0.32,
    canopyGlass,
    top: const Color(0xFF38BDF8),
    cy: 0.11,
    cz: 0.08,
  );

  static final Mesh cameraGimbal = Mesh.box(
    0.14, 0.12, 0.14,
    const Color(0xFF0F172A),
    front: const Color(0xFF06B6D4),
    cy: -0.10,
    cz: 0.28,
  );

  static final Mesh boomArmFrontRight = Mesh.box(
    0.45, 0.04, 0.05,
    carbonArm,
    cx: 0.30,
    cz: 0.28,
  );

  static final Mesh boomArmFrontLeft = Mesh.box(
    0.45, 0.04, 0.05,
    carbonArm,
    cx: -0.30,
    cz: 0.28,
  );

  static final Mesh boomArmRearRight = Mesh.box(
    0.45, 0.04, 0.05,
    carbonArm,
    cx: 0.30,
    cz: -0.28,
  );

  static final Mesh boomArmRearLeft = Mesh.box(
    0.45, 0.04, 0.05,
    carbonArm,
    cx: -0.30,
    cz: -0.28,
  );

  static final Mesh motorPod = Mesh.cylinder(
    0.08, 0.12,
    motorTitanium,
    capColor: const Color(0xFF64748B),
    segments: 10,
  );

  static final Mesh propellerBlade = Mesh.box(
    0.48, 0.015, 0.06,
    propCarbon,
    top: const Color(0xFF475569),
  );

  static final Mesh navLedBoxGreen = Mesh.box(
    0.05, 0.05, 0.05,
    navLedGreen,
    glow: true,
  );

  static final Mesh navLedBoxRed = Mesh.box(
    0.05, 0.05, 0.05,
    navLedRed,
    glow: true,
  );

  static final Mesh navLedBoxWhite = Mesh.box(
    0.05, 0.05, 0.05,
    navLedWhite,
    glow: true,
  );

  static final Mesh skidLeg = Mesh.box(
    0.03, 0.14, 0.03,
    carbonArm,
  );

  static final Mesh skidRail = Mesh.box(
    0.03, 0.03, 0.54,
    const Color(0xFF334155),
  );

  static final Mesh beaconTower = Mesh.box(
    0.4, 3.2, 0.4,
    const Color(0xFF334155),
    top: const Color(0xFFEF4444),
    front: const Color(0xFFF59E0B),
  );

  static final Mesh beaconLight = Mesh.box(
    0.3, 0.3, 0.3,
    const Color(0xFFEF4444),
    glow: true,
  );

  static final Mesh waypointGate = Mesh.box(
    0.2, 3.0, 0.2,
    gateRingNeon,
    glow: true,
  );

  static final Mesh waypointGateTop = Mesh.box(
    3.0, 0.2, 0.2,
    gateRingNeon,
    glow: true,
  );

  /// Generates dynamic 3D parts for the Drone given world position, attitude, and propeller spin angle.
  static List<Part> buildDrone({
    required double x,
    required double y,
    required double z,
    required double roll,
    required double pitch,
    required double yaw,
    required double propAngle,
    required bool isArmed,
  }) {
    final parts = <Part>[];

    // Main fuselage & pod
    final bodyPart = Part(fuselageBody, x: x, y: y, z: z, roll: roll, pitch: pitch, yaw: yaw);
    final canopyPart = Part(canopyPod, x: x, y: y, z: z, roll: roll, pitch: pitch, yaw: yaw);
    final cameraPart = Part(cameraGimbal, x: x, y: y, z: z, roll: roll, pitch: pitch, yaw: yaw);

    // Boom arms
    final armFR = Part(boomArmFrontRight, x: x, y: y, z: z, roll: roll, pitch: pitch, yaw: yaw);
    final armFL = Part(boomArmFrontLeft, x: x, y: y, z: z, roll: roll, pitch: pitch, yaw: yaw);
    final armRR = Part(boomArmRearRight, x: x, y: y, z: z, roll: roll, pitch: pitch, yaw: yaw);
    final armRL = Part(boomArmRearLeft, x: x, y: y, z: z, roll: roll, pitch: pitch, yaw: yaw);

    parts.addAll([bodyPart, canopyPart, cameraPart, armFR, armFL, armRR, armRL]);

    // Skid rails & legs
    bodyPart.computeMatrix();
    void addMountedPart(Mesh mesh, double lx, double ly, double lz, {double customYaw = 0}) {
      final wx = x + bodyPart.m00 * lx + bodyPart.m01 * ly + bodyPart.m02 * lz;
      final wy = y + bodyPart.m10 * lx + bodyPart.m11 * ly + bodyPart.m12 * lz;
      final wz = z + bodyPart.m20 * lx + bodyPart.m21 * ly + bodyPart.m22 * lz;
      parts.add(Part(mesh, x: wx, y: wy, z: wz, roll: roll, pitch: pitch, yaw: yaw + customYaw));
    }

    // Landing gear skids
    addMountedPart(skidLeg, 0.16, -0.12, 0.18);
    addMountedPart(skidLeg, 0.16, -0.12, -0.18);
    addMountedPart(skidLeg, -0.16, -0.12, 0.18);
    addMountedPart(skidLeg, -0.16, -0.12, -0.18);
    addMountedPart(skidRail, 0.16, -0.18, 0.0);
    addMountedPart(skidRail, -0.16, -0.18, 0.0);

    // Motor pods at the 4 wingtips
    const armX = 0.44;
    const armZ = 0.38;
    const motorY = 0.06;

    addMountedPart(motorPod, armX, motorY, armZ);
    addMountedPart(motorPod, -armX, motorY, armZ);
    addMountedPart(motorPod, armX, motorY, -armZ);
    addMountedPart(motorPod, -armX, motorY, -armZ);

    // Navigation LEDs
    addMountedPart(navLedBoxGreen, armX + 0.04, motorY + 0.06, armZ); // Right Front = Green
    addMountedPart(navLedBoxRed, -armX - 0.04, motorY + 0.06, armZ); // Left Front = Red
    addMountedPart(navLedBoxWhite, armX + 0.04, motorY + 0.06, -armZ);
    addMountedPart(navLedBoxWhite, -armX - 0.04, motorY + 0.06, -armZ);

    // 4 Rotating Propellers
    final pAngle1 = isArmed ? propAngle : 0.0;
    final pAngle2 = isArmed ? -propAngle * 1.1 : 0.0;

    addMountedPart(propellerBlade, armX, motorY + 0.08, armZ, customYaw: pAngle1);
    addMountedPart(propellerBlade, -armX, motorY + 0.08, armZ, customYaw: pAngle2);
    addMountedPart(propellerBlade, armX, motorY + 0.08, -armZ, customYaw: pAngle2);
    addMountedPart(propellerBlade, -armX, motorY + 0.08, -armZ, customYaw: pAngle1);

    return parts;
  }

  /// Builds the 3D ground geometry: helipad, markings, runway tarmac, and grass field.
  static List<GroundPoly> buildEnvironmentGround({
    required double droneX,
    required double droneY,
    required double droneZ,
  }) {
    final ground = <GroundPoly>[];

    // Wide terrain field (dark avionics airfield ground)
    ground.add(GroundPoly.rect(-60, -60, 60, 60, const Color(0xFF090D16)));

    // Runway / apron
    ground.add(GroundPoly.rect(-6, -30, 6, 30, runwayDark, y: 0.01));

    // Runway center dashes
    for (var z = -26.0; z <= 26.0; z += 5.0) {
      ground.add(GroundPoly.rect(-0.25, z - 1.2, 0.25, z + 1.2, tarmacLine, y: 0.02));
    }

    // Circular Landing Pad (Home base at 0, 0)
    ground.add(GroundPoly.circle(0, 0, 4.5, const Color(0xFF1E293B), y: 0.02, sides: 20));
    ground.addAll(GroundPoly.ring(0, 0, 4.0, 4.3, tarmacLine, y: 0.03, sides: 16));
    ground.addAll(GroundPoly.ring(0, 0, 2.2, 2.4, const Color(0xFF38BDF8), y: 0.03, sides: 16));

    // "H" Helipad mark in center of landing pad
    ground.add(GroundPoly.rect(-1.2, -1.0, -0.8, 1.0, tarmacLine, y: 0.04));
    ground.add(GroundPoly.rect(0.8, -1.0, 1.2, 1.0, tarmacLine, y: 0.04));
    ground.add(GroundPoly.rect(-0.8, -0.2, 0.8, 0.2, tarmacLine, y: 0.04));

    // Landing Pad safety boundary squares
    ground.add(GroundPoly.rect(-5.2, -5.2, -4.8, 5.2, const Color(0xFFEF4444), y: 0.02));
    ground.add(GroundPoly.rect(4.8, -5.2, 5.2, 5.2, const Color(0xFFEF4444), y: 0.02));

    // Soft projected drone shadow on the ground (scales and fades with altitude)
    final alt = math.max(0.1, droneY);
    final shadowScale = math.max(0.4, 1.4 - (alt * 0.1));
    final shadowAlpha = math.max(0.1, 0.6 - (alt * 0.08));
    ground.add(GroundPoly.circle(
      droneX,
      droneZ,
      0.65 * shadowScale,
      Color.fromRGBO(0, 0, 0, shadowAlpha),
      y: 0.05,
      sides: 16,
    ));

    return ground;
  }

  /// Builds static 3D world props: beacon towers, waypoint gates in the sky.
  static List<Part> buildEnvironmentSolids() {
    final parts = <Part>[];

    // 4 Corner beacon towers
    void addBeacon(double x, double z) {
      parts.add(Part(beaconTower, x: x, y: 1.6, z: z));
      parts.add(Part(beaconLight, x: x, y: 3.35, z: z, bright: 1.5));
    }

    addBeacon(-7.0, -7.0);
    addBeacon(7.0, -7.0);
    addBeacon(-7.0, 7.0);
    addBeacon(7.0, 7.0);

    // Aerial Waypoint Gates (ring structures in 3D air to fly through)
    void addGate(double x, double y, double z, double yaw) {
      parts.add(Part(waypointGate, x: x - 1.4, y: y, z: z, yaw: yaw, bright: 1.3));
      parts.add(Part(waypointGate, x: x + 1.4, y: y, z: z, yaw: yaw, bright: 1.3));
      parts.add(Part(waypointGateTop, x: x, y: y + 1.5, z: z, yaw: yaw, bright: 1.3));
      parts.add(Part(waypointGateTop, x: x, y: y - 1.5, z: z, yaw: yaw, bright: 1.3));
    }

    addGate(0, 3.2, 12, 0);
    addGate(6, 4.0, 20, 0.4);
    addGate(-6, 5.0, 26, -0.4);

    return parts;
  }
}
