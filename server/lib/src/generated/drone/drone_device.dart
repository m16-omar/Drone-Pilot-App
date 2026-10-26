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
import 'package:drone_control_pilot_server/src/generated/protocol.dart' as _i2;

abstract class DroneDevice
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  DroneDevice._({
    required this.deviceId,
    required this.name,
    required this.model,
    required this.firmwareVersion,
    required this.capabilities,
    required this.registeredAt,
  });

  factory DroneDevice({
    required String deviceId,
    required String name,
    required String model,
    required String firmwareVersion,
    required List<String> capabilities,
    required DateTime registeredAt,
  }) = _DroneDeviceImpl;

  factory DroneDevice.fromJson(Map<String, dynamic> jsonSerialization) {
    return DroneDevice(
      deviceId: jsonSerialization['deviceId'] as String,
      name: jsonSerialization['name'] as String,
      model: jsonSerialization['model'] as String,
      firmwareVersion: jsonSerialization['firmwareVersion'] as String,
      capabilities: _i2.Protocol().deserialize<List<String>>(
        jsonSerialization['capabilities'],
      ),
      registeredAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['registeredAt'],
      ),
    );
  }

  String deviceId;

  String name;

  String model;

  String firmwareVersion;

  List<String> capabilities;

  DateTime registeredAt;

  /// Returns a shallow copy of this [DroneDevice]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DroneDevice copyWith({
    String? deviceId,
    String? name,
    String? model,
    String? firmwareVersion,
    List<String>? capabilities,
    DateTime? registeredAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DroneDevice',
      'deviceId': deviceId,
      'name': name,
      'model': model,
      'firmwareVersion': firmwareVersion,
      'capabilities': capabilities.toJson(),
      'registeredAt': registeredAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DroneDevice',
      'deviceId': deviceId,
      'name': name,
      'model': model,
      'firmwareVersion': firmwareVersion,
      'capabilities': capabilities.toJson(),
      'registeredAt': registeredAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _DroneDeviceImpl extends DroneDevice {
  _DroneDeviceImpl({
    required String deviceId,
    required String name,
    required String model,
    required String firmwareVersion,
    required List<String> capabilities,
    required DateTime registeredAt,
  }) : super._(
         deviceId: deviceId,
         name: name,
         model: model,
         firmwareVersion: firmwareVersion,
         capabilities: capabilities,
         registeredAt: registeredAt,
       );

  /// Returns a shallow copy of this [DroneDevice]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DroneDevice copyWith({
    String? deviceId,
    String? name,
    String? model,
    String? firmwareVersion,
    List<String>? capabilities,
    DateTime? registeredAt,
  }) {
    return DroneDevice(
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      model: model ?? this.model,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      capabilities: capabilities ?? this.capabilities.map((e0) => e0).toList(),
      registeredAt: registeredAt ?? this.registeredAt,
    );
  }
}
