import 'package:flutter/foundation.dart';

enum FlightActionType {
  takeOff,
  land,
  hoverHold,
  orbitScan,
  emergencyStop,
  preFlightCheck,
  setAltitude,
}

@immutable
class FlightAction {
  const FlightAction({
    required this.type,
    required this.label,
    this.params = const {},
    this.requiresConfirmation = true,
  });

  final FlightActionType type;
  final String label;
  final Map<String, dynamic> params;
  final bool requiresConfirmation;
}

@immutable
class AiMessage {
  const AiMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.action,
    this.isActionExecuted = false,
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final FlightAction? action;
  final bool isActionExecuted;

  AiMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    FlightAction? action,
    bool? isActionExecuted,
  }) {
    return AiMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      action: action ?? this.action,
      isActionExecuted: isActionExecuted ?? this.isActionExecuted,
    );
  }
}
