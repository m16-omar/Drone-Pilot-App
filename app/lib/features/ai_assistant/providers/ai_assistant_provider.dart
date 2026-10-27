import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../drone_connection/services/udp_drone_link.dart';
import '../../telemetry/models/drone_telemetry.dart';
import '../../telemetry/providers/drone_providers.dart';
import '../models/ai_message.dart';
import '../services/ai_copilot_service.dart';

class AiAssistantState {
  const AiAssistantState({
    this.messages = const [],
    this.isThinking = false,
    this.activeWarning,
  });

  final List<AiMessage> messages;
  final bool isThinking;
  final String? activeWarning;

  AiAssistantState copyWith({
    List<AiMessage>? messages,
    bool? isThinking,
    String? activeWarning,
  }) {
    return AiAssistantState(
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
      activeWarning: activeWarning ?? this.activeWarning,
    );
  }
}

final aiAssistantProvider =
    NotifierProvider<AiAssistantNotifier, AiAssistantState>(
  AiAssistantNotifier.new,
);

class AiAssistantNotifier extends Notifier<AiAssistantState> {
  final AiCopilotService _service = const AiCopilotService();

  @override
  AiAssistantState build() {
    // Initial friendly greeting with telemetry overview
    final initialGreeting = AiMessage(
      id: 'init_welcome',
      text: '👋 AI Flight Co-Pilot standing by.\n'
          'I can execute flight maneuvers, run pre-flight diagnostics, hold altitude, or guide you through Mode 2 controls.\n\n'
          'Try typing or tapping: "Pre-Flight Diagnostics" or "Takeoff to 2m".',
      isUser: false,
      timestamp: DateTime.now(),
      action: const FlightAction(
        type: FlightActionType.preFlightCheck,
        label: 'RUN PRE-FLIGHT CHECK',
        requiresConfirmation: false,
      ),
    );

    return AiAssistantState(messages: [initialGreeting]);
  }

  /// Sends a pilot query to the AI co-pilot
  Future<void> sendQuery(String query) async {
    if (query.trim().isEmpty) return;

    final userMsg = AiMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: query.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isThinking: true,
    );

    // Short simulated cognitive latency for realism
    await Future.delayed(const Duration(milliseconds: 350));

    final telemetry =
        ref.read(droneTelemetryProvider).value ?? DroneTelemetry.initial;
    final linkState =
        ref.read(droneLinkStateProvider).value ?? DroneLinkState.disconnected;

    final aiReply = _service.processQuery(
      query: query,
      telemetry: telemetry,
      linkState: linkState,
    );

    state = state.copyWith(
      messages: [...state.messages, aiReply],
      isThinking: false,
    );
  }

  /// Executes an action attached to an AI message
  Future<void> executeAction(AiMessage message) async {
    final action = message.action;
    if (action == null || message.isActionExecuted) return;

    final link = ref.read(droneLinkProvider);
    await _service.executeAction(action, link);

    // Mark action executed
    final updatedList = state.messages.map((m) {
      if (m.id == message.id) {
        return m.copyWith(isActionExecuted: true);
      }
      return m;
    }).toList();

    // Append confirmation notice from AI
    final confirmMsg = AiMessage(
      id: 'exec_${DateTime.now().millisecondsSinceEpoch}',
      text: '✅ Action dispatched: "${action.label}". Telemetry setpoints transmitted to drone via UDP.',
      isUser: false,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(messages: [...updatedList, confirmMsg]);
  }

  /// Clears chat history and restores initial welcome
  void clearChat() {
    state = build();
  }
}
