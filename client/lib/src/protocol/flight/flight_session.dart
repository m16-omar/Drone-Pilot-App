/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class FlightSession implements _i1.SerializableModel {
  FlightSession._({
    required this.sessionId,
    required this.droneId,
    required this.startTime,
    this.endTime,
    required this.maxAltitudeMeters,
    required this.maxSpeedMps,
    this.durationSeconds,
    required this.status,
    this.notes,
  });

  factory FlightSession({
    required String sessionId,
    required String droneId,
    required DateTime startTime,
    DateTime? endTime,
    required double maxAltitudeMeters,
    required double maxSpeedMps,
    int? durationSeconds,
    required String status,
    String? notes,
  }) = _FlightSessionImpl;

  factory FlightSession.fromJson(Map<String, dynamic> jsonSerialization) {
    return FlightSession(
      sessionId: jsonSerialization['sessionId'] as String,
      droneId: jsonSerialization['droneId'] as String,
      startTime: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['startTime'],
      ),
      endTime: jsonSerialization['endTime'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['endTime']),
      maxAltitudeMeters: (jsonSerialization['maxAltitudeMeters'] as num)
          .toDouble(),
      maxSpeedMps: (jsonSerialization['maxSpeedMps'] as num).toDouble(),
      durationSeconds: jsonSerialization['durationSeconds'] as int?,
      status: jsonSerialization['status'] as String,
      notes: jsonSerialization['notes'] as String?,
    );
  }

  String sessionId;

  String droneId;

  DateTime startTime;

  DateTime? endTime;

  double maxAltitudeMeters;

  double maxSpeedMps;

  int? durationSeconds;

  String status;

  String? notes;

  /// Returns a shallow copy of this [FlightSession]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  FlightSession copyWith({
    String? sessionId,
    String? droneId,
    DateTime? startTime,
    DateTime? endTime,
    double? maxAltitudeMeters,
    double? maxSpeedMps,
    int? durationSeconds,
    String? status,
    String? notes,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FlightSession',
      'sessionId': sessionId,
      'droneId': droneId,
      'startTime': startTime.toJson(),
      if (endTime != null) 'endTime': endTime?.toJson(),
      'maxAltitudeMeters': maxAltitudeMeters,
      'maxSpeedMps': maxSpeedMps,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      'status': status,
      if (notes != null) 'notes': notes,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FlightSessionImpl extends FlightSession {
  _FlightSessionImpl({
    required String sessionId,
    required String droneId,
    required DateTime startTime,
    DateTime? endTime,
    required double maxAltitudeMeters,
    required double maxSpeedMps,
    int? durationSeconds,
    required String status,
    String? notes,
  }) : super._(
         sessionId: sessionId,
         droneId: droneId,
         startTime: startTime,
         endTime: endTime,
         maxAltitudeMeters: maxAltitudeMeters,
         maxSpeedMps: maxSpeedMps,
         durationSeconds: durationSeconds,
         status: status,
         notes: notes,
       );

  /// Returns a shallow copy of this [FlightSession]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  FlightSession copyWith({
    String? sessionId,
    String? droneId,
    DateTime? startTime,
    Object? endTime = _Undefined,
    double? maxAltitudeMeters,
    double? maxSpeedMps,
    Object? durationSeconds = _Undefined,
    String? status,
    Object? notes = _Undefined,
  }) {
    return FlightSession(
      sessionId: sessionId ?? this.sessionId,
      droneId: droneId ?? this.droneId,
      startTime: startTime ?? this.startTime,
      endTime: endTime is DateTime? ? endTime : this.endTime,
      maxAltitudeMeters: maxAltitudeMeters ?? this.maxAltitudeMeters,
      maxSpeedMps: maxSpeedMps ?? this.maxSpeedMps,
      durationSeconds: durationSeconds is int?
          ? durationSeconds
          : this.durationSeconds,
      status: status ?? this.status,
      notes: notes is String? ? notes : this.notes,
    );
  }
}
