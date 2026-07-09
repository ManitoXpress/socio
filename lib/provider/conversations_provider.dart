import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../ServiceResponse/get.dart';

/// Provider del trabajador para el sistema de mensajería.
///
/// ⚠️ NO usa Firestore directamente — todo va por REST al backend,
/// igual que en manito_cliente. Esto evita problemas de PERMISSION_DENIED
/// y de índices compuestos de Firestore.
///
/// Patrón: polling periódico según README_CHAT_WORKER.md
class ConversationsProvider extends ChangeNotifier {
  final String serviceId;
  final ApiService2 apiService2;

  ConversationsProvider({
    required this.serviceId,
    required this.apiService2,
  }) {
    // Arranca el polling del inbox automáticamente al crear el provider
    _startInboxPolling();
  }

  String get currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── Inbox (lista de conversaciones) ────────────────────────────────────────

  final _inboxController =
      StreamController<List<ConversationModel>>.broadcast();

  /// Stream del inbox — emite listas desde REST (no Firestore).
  /// Sigue siendo un Stream para no cambiar conversations_inbox.dart.
  Stream<List<ConversationModel>> get inboxStream => _inboxController.stream;

  Timer? _inboxTimer;

  void _startInboxPolling() {
    _fetchInbox(); // carga inmediata
    _inboxTimer?.cancel();
    _inboxTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchInbox();
    });
  }

  Future<void> _fetchInbox() async {
    try {
      final data = await apiService2.getConversationsByServiceId(serviceId);
      if (_inboxController.isClosed) return;
      final list = data
          .map((m) => ConversationModel.fromMap(m['id'] as String? ?? '', m))
          .toList();
      // Ordenar por lastAt descendente en Dart
      list.sort((a, b) {
        if (a.lastAt == null && b.lastAt == null) return 0;
        if (a.lastAt == null) return 1;
        if (b.lastAt == null) return -1;
        return b.lastAt!.compareTo(a.lastAt!);
      });
      _inboxController.add(list);
    } catch (e) {
      debugPrint('[ConversationsProvider] Error _fetchInbox: $e');
      // En caso de error emite lista vacía para no romper la UI
      if (!_inboxController.isClosed) _inboxController.add([]);
    }
  }

  // ── Estado del chat abierto ─────────────────────────────────────────────────

  String? _openConvId;
  String? get conversationId => _openConvId;

  String? chatError;

  // ── Mensajes en memoria (alimentados por polling REST) ─────────────────────

  List<MessageModel> _messages = [];
  List<MessageModel> get messages => _messages;

  Timer? _pollTimer;

  /// Inicia el polling de mensajes REST para una conversación.
  /// Llamar desde ChatScreen.initState().
  void startMessagesPolling(String convId) {
    if (_openConvId == convId && _pollTimer?.isActive == true) return;
    _openConvId = convId;
    chatError = null;

    _fetchMessages(convId); // carga inicial inmediata
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchMessages(convId);
    });
  }

  /// Detiene el polling y limpia el estado del chat.
  /// Llamar desde ChatScreen.dispose().
  void stopMessagesPolling() {
    _pollTimer?.cancel();
    _openConvId = null;
    _messages = [];
    chatError = null;
    notifyListeners();
  }

  Future<void> _fetchMessages(String convId) async {
    try {
      final rawList = await apiService2.getConversationMessages(convId);
      _messages = rawList
          .map((m) => MessageModel.fromMap(m['id'] as String? ?? '', m))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[ConversationsProvider] Error _fetchMessages: $e');
    }
  }

  // ── Enviar mensaje (POST REST + refresh inmediato) ──────────────────────────

  Future<void> sendMessage(String convId, String text) async {
    await apiService2.sendConversationMessage(convId, text);
    await _fetchMessages(convId);
  }

  // ── Marcar como leído ───────────────────────────────────────────────────────

  Future<void> markAsRead(String convId) async {
    try {
      await apiService2.markConversationAsRead(convId);
    } catch (e) {
      debugPrint('[ConversationsProvider] Error markAsRead: $e');
    }
  }

  // ── Limpieza ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _inboxTimer?.cancel();
    _pollTimer?.cancel();
    _inboxController.close();
    super.dispose();
  }
}
