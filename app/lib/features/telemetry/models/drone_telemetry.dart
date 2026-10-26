class DroneTelemetry {
  const DroneTelemetry({
    required this.version,
    required this.sequence,
    required this.deviceId,
    required this.timestampMs,
    required this.isArmed,
    required this.batteryPercent,
    required this.rollDeg,
    required this.pitchDeg,
    required this.yawDeg,
    required this.altitudeMeters,
    required this.speedMps,
    required this.hasGpsFix,
    required this.linkQualityPercent,
    this.flightMode = 'MANUAL',
  });

  final int version;
  final int sequence;
  final String deviceId;
  final int timestampMs;
  final bool isArmed;
  final double batteryPercent;
  final double rollDeg;
  final double pitchDeg;
  final double yawDeg;
  final double altitudeMeters;
  final double speedMps;
  final bool hasGpsFix;
  final int linkQualityPercent;
  final String flightMode;

  factory DroneTelemetry.fromJson(Map<String, dynamic> json) {
    return DroneTelemetry(
      version: (json['v'] as num?)?.toInt() ?? 1,
      sequence: (json['seq'] as num?)?.toInt() ?? 0,
      deviceId: json['device_id'] as String? ?? 'UNKNOWN',
      timestampMs: (json['timestamp_ms'] as num?)?.toInt() ?? 0,
      isArmed: json['armed'] == true,
      batteryPercent: (json['battery_percent'] as num?)?.toDouble() ?? 0.0,
      rollDeg: (json['roll_deg'] as num?)?.toDouble() ?? 0.0,
      pitchDeg: (json['pitch_deg'] as num?)?.toDouble() ?? 0.0,
      yawDeg: (json['yaw_deg'] as num?)?.toDouble() ?? 0.0,
      altitudeMeters: (json['altitude_m'] as num?)?.toDouble() ?? 0.0,
      speedMps: (json['speed_mps'] as num?)?.toDouble() ?? 0.0,
      hasGpsFix: json['gps_fix'] == true,
      linkQualityPercent: (json['link_quality_percent'] as num?)?.toInt() ?? 100,
      flightMode: json['flight_mode'] as String? ?? 'MANUAL',
    );
  }

  static const DroneTelemetry initial = DroneTelemetry(
    version: 1,
    sequence: 0,
    deviceId: 'SEARCHING...',
    timestampMs: 0,
    isArmed: false,
    batteryPercent: 0.0,
    rollDeg: 0.0,
    pitchDeg: 0.0,
    yawDeg: 0.0,
    altitudeMeters: 0.0,
    speedMps: 0.0,
    hasGpsFix: false,
    linkQualityPercent: 0,
    flightMode: 'DISCONNECTED',
  );
}
