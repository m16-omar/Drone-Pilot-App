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

import 'package:serverpod/serverpod.dart' as _i1;

abstract class SystemStatus
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  SystemStatus._({
    required this.service,
    required this.status,
    required this.version,
    required this.mode,
  });

  factory SystemStatus({
    required String service,
    required String status,
    required String version,
    required String mode,
  }) = _SystemStatusImpl;

  factory SystemStatus.fromJson(Map<String, dynamic> jsonSerialization) {
    return SystemStatus(
      service: jsonSerialization['service'] as String,
      status: jsonSerialization['status'] as String,
      version: jsonSerialization['version'] as String,
      mode: jsonSerialization['mode'] as String,
    );
  }

  String service;

  String status;

  String version;

  String mode;

  /// Returns a shallow copy of this [SystemStatus]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SystemStatus copyWith({
    String? service,
    String? status,
    String? version,
    String? mode,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SystemStatus',
      'service': service,
      'status': status,
      'version': version,
      'mode': mode,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SystemStatus',
      'service': service,
      'status': status,
      'version': version,
      'mode': mode,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _SystemStatusImpl extends SystemStatus {
  _SystemStatusImpl({
    required String service,
    required String status,
    required String version,
    required String mode,
  }) : super._(
         service: service,
         status: status,
         version: version,
         mode: mode,
       );

  /// Returns a shallow copy of this [SystemStatus]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SystemStatus copyWith({
    String? service,
    String? status,
    String? version,
    String? mode,
  }) {
    return SystemStatus(
      service: service ?? this.service,
      status: status ?? this.status,
      version: version ?? this.version,
      mode: mode ?? this.mode,
    );
  }
}
