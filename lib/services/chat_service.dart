import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class ChatService {
  ChatService();

  // Cache local de mensajes
  static const int _maxCachedMessagesPerConversation = 80;
  static final Map<int, List<ChatMessageItem>> _recentMessagesCache =
      <int, List<ChatMessageItem>>{};

  static List<ChatMessageItem> getCachedMessages(int conversationId) {
    return List<ChatMessageItem>.unmodifiable(
      _recentMessagesCache[conversationId] ?? const <ChatMessageItem>[],
    );
  }

  static void cacheMessages(
    int conversationId,
    List<ChatMessageItem> messages,
  ) {
    _recentMessagesCache[conversationId] =
        _trimCachedMessages(messages).toList(growable: false);
  }

  static void upsertCachedMessage(ChatMessageItem message) {
    final List<ChatMessageItem> next = List<ChatMessageItem>.of(
      _recentMessagesCache[message.conversationId] ??
          const <ChatMessageItem>[],
    );
    final int existingIndex = next.indexWhere((item) => item.id == message.id);

    if (existingIndex >= 0) {
      next[existingIndex] = message;
    } else {
      next.add(message);
    }

    next.sort(_compareMessagesForCache);
    cacheMessages(message.conversationId, next);
  }

  // ============ REST ENDPOINTS (para sincronización con backend) ============

  /// Obtiene conversaciones del backend (mantiene sincronización)
  Future<List<ConversationSummary>> getConversations({required String jwt}) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.backendBaseUrl}/chat/conversations'),
        headers: {'Authorization': 'Bearer $jwt'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ConversationSummary.fromJson(json)).toList();
      } else {
        throw ChatException('Failed to load conversations');
      }
    } catch (e) {
      throw ChatException('Error loading conversations: $e');
    }
  }

  /// Inicia una conversación en el backend
  Future<ConversationSummary> startConversation({
    required String jwt,
    required int vacancyId,
    required int candidateId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendBaseUrl}/chat/conversations'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'vacancyId': vacancyId,
          'candidateId': candidateId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ConversationSummary.fromJson(data);
      } else {
        final String detail = response.body.trim();
        throw ChatException(
          detail.isEmpty
              ? 'No se pudo iniciar la conversacion (HTTP ${response.statusCode}).'
              : 'No se pudo iniciar la conversacion (HTTP ${response.statusCode}): $detail',
        );
      }
    } catch (e) {
      throw ChatException('Error starting conversation: $e');
    }
  }

  // ============ CHAT MESSAGE ENDPOINTS ============

  /// Obtiene mensajes desde backend
  Future<List<ChatMessageItem>> getMessages({
    required String jwt,
    required int conversationId,
    int limit = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConfig.backendBaseUrl}/chat/conversations/$conversationId/messages?limit=$limit',
        ),
        headers: {'Authorization': 'Bearer $jwt'},
      );

      if (response.statusCode != 200) {
        throw ChatException('Failed to load messages');
      }

      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      final List<ChatMessageItem> messages = data
          .map(
            (item) => ChatMessageItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);

      cacheMessages(conversationId, messages);
      return messages;
    } catch (e) {
      throw ChatException('Failed to load messages: $e');
    }
  }

  /// Envía un mensaje al backend y devuelve el persistido
  Future<ChatMessageItem> sendMessage({
    required String jwt,
    required int conversationId,
    required String content,
    required int currentUserId,
    String? clientMessageId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${AppConfig.backendBaseUrl}/chat/conversations/$conversationId/messages',
        ),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': content,
          'clientMessageId': clientMessageId,
        }),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw ChatException('Failed to send message');
      }

      final ChatMessageItem message = ChatMessageItem.fromJson(
        Map<String, dynamic>.from(jsonDecode(response.body) as Map),
      );

      final ChatMessageItem normalizedMessage = ChatMessageItem(
        id: message.id,
        conversationId: message.conversationId,
        senderId: message.senderId,
        senderRole: message.senderRole,
        content: message.content,
        createdAt: message.createdAt,
        mine: message.senderId == currentUserId,
        clientMessageId: message.clientMessageId ?? clientMessageId,
      );

      upsertCachedMessage(normalizedMessage);
      return normalizedMessage;
    } catch (e) {
      throw ChatException('Failed to send message: $e');
    }
  }

  /// Stream de inserciones de mensajes vía Supabase Realtime.
  Stream<ChatMessageItem> streamMessageEvents({
    required int conversationId,
    required int currentUserId,
  }) {
    if (!AppConfig.isSupabaseChatConfigured) {
      debugPrint(
        'Supabase chat realtime disabled: missing SUPABASE_URL or SUPABASE_ANON_KEY.',
      );
      return const Stream<ChatMessageItem>.empty();
    }

    final StreamController<ChatMessageItem> controller =
        StreamController<ChatMessageItem>();
    final SupabaseClient client = Supabase.instance.client;
    final String channelName =
        'chat-room-$conversationId-${DateTime.now().microsecondsSinceEpoch}';
    late final RealtimeChannel channel;

    controller.onListen = () {
      channel = client.channel(channelName)
        ..onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: AppConfig.supabaseMessagesTable,
          callback: (PostgresChangePayload payload) {
            final Map<String, dynamic> row =
                Map<String, dynamic>.from(payload.newRecord);
            final int incomingConversationId = _toInt(row['conversation_id']);
            if (incomingConversationId != conversationId) {
              debugPrint(
                'Supabase chat payload ignored: incomingConversationId=$incomingConversationId expected=$conversationId',
              );
              return;
            }
            debugPrint(
              'Supabase chat payload received: conversationId=$incomingConversationId messageId=${row['message_id'] ?? row['id']}',
            );
            final ChatMessageItem message = ChatMessageItem(
              id: _toInt(row['message_id'] ?? row['id']),
              conversationId: incomingConversationId,
              senderId: _toInt(row['sender_id']),
              senderRole: row['sender_role']?.toString() ?? '',
              content: row['content']?.toString() ?? '',
              createdAt: _toDateTime(row['created_at']),
              mine: _toInt(row['sender_id']) == currentUserId,
              clientMessageId: row['client_message_id']?.toString(),
            );
            controller.add(message);
          },
        )
        ..subscribe((status, [error]) {
          debugPrint(
            'Supabase chat channel[$channelName] status=$status error=$error',
          );
        });
    };

    controller.onCancel = () {
      client.removeChannel(channel);
    };

    return controller.stream;
  }

  /// Stream de notificaciones realtime por usuario (likes, decisiones, matches).
  Stream<RealtimeNotificationEvent> streamNotificationEvents({
    required int currentUserId,
  }) {
    if (!AppConfig.isSupabaseChatConfigured || currentUserId <= 0) {
      return const Stream<RealtimeNotificationEvent>.empty();
    }

    final StreamController<RealtimeNotificationEvent> controller =
        StreamController<RealtimeNotificationEvent>();
    final SupabaseClient client = Supabase.instance.client;
    final String channelName =
        'notifications-user-$currentUserId-${DateTime.now().microsecondsSinceEpoch}';
    late final RealtimeChannel channel;

    controller.onListen = () {
      channel = client.channel(channelName)
        ..onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: AppConfig.supabaseNotificationsTable,
          callback: (PostgresChangePayload payload) {
            final Map<String, dynamic> row =
                Map<String, dynamic>.from(payload.newRecord);
            final int userId = _toInt(row['user_id']);
            if (userId != currentUserId) {
              return;
            }

            final Map<String, dynamic> payloadMap =
                row['payload'] is Map<String, dynamic>
                ? Map<String, dynamic>.from(row['payload'] as Map<String, dynamic>)
                : <String, dynamic>{};

            controller.add(
              RealtimeNotificationEvent(
                id: _toInt(row['id']),
                userId: userId,
                type: row['type']?.toString() ?? '',
                payload: payloadMap,
                createdAt: _toDateTime(row['created_at']),
              ),
            );
          },
        )
        ..subscribe((status, [error]) {
          debugPrint(
            'Supabase notification channel[$channelName] status=$status error=$error',
          );
        });
    };

    controller.onCancel = () {
      client.removeChannel(channel);
    };

    return controller.stream;
  }

  /// Marca una conversación como leída
  Future<void> markAsRead({
    required String jwt,
    required int conversationId,
  }) async {
    try {
      // Llamar al backend para actualizar unreadCount
      await http.post(
        Uri.parse('${AppConfig.backendBaseUrl}/chat/conversations/$conversationId/read'),
        headers: {'Authorization': 'Bearer $jwt'},
      );
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  static Iterable<ChatMessageItem> _trimCachedMessages(
    List<ChatMessageItem> messages,
  ) {
    if (messages.length <= _maxCachedMessagesPerConversation) {
      return messages;
    }
    return messages.skip(messages.length - _maxCachedMessagesPerConversation);
  }

  static int _compareMessagesForCache(ChatMessageItem a, ChatMessageItem b) {
    final bool aPersisted = a.id > 0;
    final bool bPersisted = b.id > 0;
    if (aPersisted && bPersisted) {
      return a.id.compareTo(b.id);
    }
    if (aPersisted != bPersisted) {
      return aPersisted ? -1 : 1;
    }

    final DateTime? left = a.createdAt;
    final DateTime? right = b.createdAt;
    if (left == null && right == null) {
      return a.id.compareTo(b.id);
    }
    if (left == null) {
      return -1;
    }
    if (right == null) {
      return 1;
    }
    return left.compareTo(right);
  }
}

// ============ DATA MODELS ============

class ConversationSummary {
  ConversationSummary({
    required this.conversationId,
    required this.vacancyId,
    required this.vacancyTitle,
    required this.counterpartId,
    required this.counterpartName,
    required this.counterpartRole,
    required this.initiatedByUserId,
    required this.lastMessagePreview,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final int conversationId;
  final int vacancyId;
  final String vacancyTitle;
  final int counterpartId;
  final String counterpartName;
  final String counterpartRole;
  final int initiatedByUserId;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get matchKey => '$vacancyId:$counterpartId';

  static ConversationSummary fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      conversationId: _toInt(json['conversationId']),
      vacancyId: _toInt(json['vacancyId']),
      vacancyTitle: json['vacancyTitle']?.toString() ?? 'Vacante',
      counterpartId: _toInt(json['counterpartId']),
      counterpartName: json['counterpartName']?.toString() ?? 'Usuario',
      counterpartRole: json['counterpartRole']?.toString() ?? '',
      initiatedByUserId: _toInt(json['initiatedByUserId']),
      lastMessagePreview: json['lastMessagePreview']?.toString(),
      lastMessageAt: _toDateTime(json['lastMessageAt']),
      unreadCount: _toInt(json['unreadCount']),
      createdAt: _toDateTime(json['createdAt']),
      updatedAt: _toDateTime(json['updatedAt']),
    );
  }
}

class ChatMessageItem {
  ChatMessageItem({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderRole,
    required this.content,
    required this.createdAt,
    required this.mine,
    this.clientMessageId,
  });

  final int id;
  final int conversationId;
  final int senderId;
  final String senderRole;
  final String content;
  final DateTime? createdAt;
  final bool mine;
  final String? clientMessageId;

  static ChatMessageItem fromJson(Map<String, dynamic> json) {
    return ChatMessageItem(
      id: _toInt(json['id']),
      conversationId: _toInt(json['conversationId']),
      senderId: _toInt(json['senderId']),
      senderRole: json['senderRole']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: _toDateTime(json['createdAt']),
      mine: json['mine'] == true,
      clientMessageId: json['clientMessageId']?.toString(),
    );
  }
}

class ChatException implements Exception {
  const ChatException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RealtimeNotificationEvent {
  RealtimeNotificationEvent({
    required this.id,
    required this.userId,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime? createdAt;
}

// ============ UTILITY FUNCTIONS ============

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime? _toDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
