import 'dart:async';

import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';

class ConversationChatScreen extends StatefulWidget {
  const ConversationChatScreen({
    super.key,
    required this.jwt,
    required this.summary,
  });

  final String jwt;
  final ConversationSummary summary;

  @override
  State<ConversationChatScreen> createState() => _ConversationChatScreenState();
}

class _ConversationChatScreenState extends State<ConversationChatScreen> {
  static const Duration _backgroundSyncInterval = Duration(seconds: 12);

  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessageItem> _messages = const [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isBackgroundSyncInFlight = false;
  String? _error;
  Timer? _backgroundSyncTimer;
  StreamSubscription<ChatMessageItem>? _realtimeMessagesSubscription;

  int get _currentUserId => AuthService.extractUserIdFromJwt(widget.jwt) ?? 0;

  String get _currentUserRole =>
      AuthService.extractRoleFromJwt(widget.jwt) ?? 'CANDIDATE';

  @override
  void initState() {
    super.initState();
    final List<ChatMessageItem> cachedMessages = ChatService.getCachedMessages(
      widget.summary.conversationId,
    );
    if (cachedMessages.isNotEmpty) {
      _messages = cachedMessages;
      _isLoading = false;
      unawaited(_loadMessages(markAsRead: true, silent: true));
      _scrollToBottom();
    } else {
      unawaited(_loadMessages(markAsRead: true));
    }
    _startRealtimeMessageStream();
    _startBackgroundSyncLoop();
  }

  @override
  void dispose() {
    _backgroundSyncTimer?.cancel();
    _realtimeMessagesSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startRealtimeMessageStream() {
    _realtimeMessagesSubscription?.cancel();
    _realtimeMessagesSubscription = _chatService
        .streamMessageEvents(
          conversationId: widget.summary.conversationId,
          currentUserId: _currentUserId,
        )
        .listen(
          (ChatMessageItem incoming) {
            if (!mounted) {
              return;
            }
            final bool shouldAutoScroll = _isNearBottom();
            final bool didChange = _applyIncomingMessage(incoming);
            if (didChange) {
              ChatService.cacheMessages(widget.summary.conversationId, _messages);
              if (shouldAutoScroll) {
                _scrollToBottom();
              }
            }
            if (!incoming.mine) {
              unawaited(
                _chatService.markAsRead(
                  jwt: widget.jwt,
                  conversationId: widget.summary.conversationId,
                ),
              );
            }
          },
          onError: (Object error) {
            debugPrint('Realtime chat stream error: $error');
          },
        );
  }

  bool _applyIncomingMessage(ChatMessageItem incoming) {
    final int existingById = _messages.indexWhere((m) => m.id == incoming.id);
    if (existingById >= 0) {
      return false;
    }

    final String? incomingClientId = incoming.clientMessageId;
    if (incomingClientId != null && incomingClientId.isNotEmpty) {
      final int optimisticIndex = _messages.indexWhere(
        (m) => m.clientMessageId == incomingClientId,
      );
      if (optimisticIndex >= 0) {
        setState(() {
          final List<ChatMessageItem> next = List<ChatMessageItem>.of(_messages);
          next[optimisticIndex] = incoming;
          _messages = next;
        });
        return true;
      }
    }

    setState(() {
      final List<ChatMessageItem> next = List<ChatMessageItem>.of(_messages)
        ..add(incoming);
      next.sort(_compareMessagesForDisplay);
      _messages = next;
    });
    return true;
  }

  void _startBackgroundSyncLoop() {
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = Timer.periodic(_backgroundSyncInterval, (_) {
      unawaited(_runBackgroundSync());
    });
  }

  Future<void> _runBackgroundSync() async {
    if (!mounted || _isBackgroundSyncInFlight) {
      return;
    }
    _isBackgroundSyncInFlight = true;
    try {
      await _loadMessages(markAsRead: true, silent: true);
    } finally {
      _isBackgroundSyncInFlight = false;
    }
  }

  Future<void> _loadMessages({
    bool markAsRead = false,
    bool silent = false,
  }) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final List<ChatMessageItem> messages = await _chatService.getMessages(
        jwt: widget.jwt,
        conversationId: widget.summary.conversationId,
        limit: 40,
      );

      if (markAsRead) {
        await _chatService.markAsRead(
          jwt: widget.jwt,
          conversationId: widget.summary.conversationId,
        );
      }

      if (!mounted) {
        return;
      }

        final bool shouldScroll =
          !silent && (_messages.isEmpty || messages.length > _messages.length);

      final List<ChatMessageItem> mergedMessages =
          _mergeFetchedWithPendingOptimistic(messages);

      setState(() {
        _messages = mergedMessages;
        _isLoading = false;
      });
      ChatService.cacheMessages(widget.summary.conversationId, mergedMessages);

      if (shouldScroll) {
        _scrollToBottom();
      }
    } on ChatException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = 'No se pudo actualizar esta conversacion por ahora.';
      });
    }
  }

  Future<void> _sendMessage() async {
    final String content = _messageController.text.trim();
    if (content.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    // Optimistic UI: agrega mensaje localmente antes de esperar backend.
    final String tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final int currentUserId = _currentUserId;
    final String currentUserRole = _currentUserRole;
    
    final ChatMessageItem optimisticMessage = ChatMessageItem(
      id: -int.parse(tempId),
      clientMessageId: tempId,
      conversationId: widget.summary.conversationId,
      senderId: currentUserId,
      senderRole: currentUserRole,
      content: content,
      createdAt: DateTime.now(),
      mine: true,
    );

    setState(() {
      _messages = [..._messages, optimisticMessage];
    });
    _scrollToBottom();
    _messageController.clear();

    try {
      final ChatMessageItem persistedMessage = await _chatService.sendMessage(
        jwt: widget.jwt,
        conversationId: widget.summary.conversationId,
        content: content,
        currentUserId: currentUserId,
        clientMessageId: tempId,
      );
      
      if (!mounted) return;
      
      setState(() {
        _messages = _messages
            .map(
              (message) => message.clientMessageId == tempId
                  ? persistedMessage
                  : message,
            )
            .toList(growable: false);
      });
      ChatService.upsertCachedMessage(persistedMessage);
    } on ChatException catch (error) {
      if (!mounted) return;
      // Preserve optimistic message on transient failures; background sync can reconcile it.
      unawaited(_runBackgroundSync());
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  bool _isMatchingOptimisticMessage(
    ChatMessageItem optimistic,
    ChatMessageItem persisted,
  ) {
    final DateTime? optimisticCreatedAt = optimistic.createdAt;
    final DateTime? persistedCreatedAt = persisted.createdAt;
    if (optimistic.id >= 0 ||
        optimistic.content != persisted.content ||
        optimisticCreatedAt == null ||
        persistedCreatedAt == null) {
      return false;
    }
    return optimisticCreatedAt.difference(persistedCreatedAt).inSeconds.abs() < 10;
  }

  List<ChatMessageItem> _mergeFetchedWithPendingOptimistic(
    List<ChatMessageItem> fetched,
  ) {
    final List<ChatMessageItem> pending = _messages
        .where((message) => message.id < 0)
        .toList(growable: false);
    if (pending.isEmpty) {
      return fetched;
    }

    final List<ChatMessageItem> merged = List<ChatMessageItem>.of(fetched);
    for (final ChatMessageItem optimistic in pending) {
      final bool alreadyPersisted = fetched.any(
        (persisted) => _isMatchingOptimisticMessage(optimistic, persisted),
      );
      if (!alreadyPersisted) {
        merged.add(optimistic);
      }
    }

    merged.sort((a, b) {
      return _compareMessagesForDisplay(a, b);
    });
    return merged;
  }

  int _compareMessagesForDisplay(ChatMessageItem a, ChatMessageItem b) {
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

  bool _isNearBottom() {
    if (!_scrollController.hasClients) {
      return true;
    }
    final double max = _scrollController.position.maxScrollExtent;
    final double current = _scrollController.position.pixels;
    return (max - current) <= 140;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.summary.counterpartName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              widget.summary.vacancyTitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: JobSwipeTheme.primaryIndigo.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: JobSwipeTheme.primaryIndigo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Conversacion activa',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Usa este espacio para coordinar siguientes pasos con contexto de la vacante.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, size: 42),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _loadMessages(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.forum_rounded,
                  size: 34,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'La conversacion ya esta lista',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Envia el primer mensaje para iniciar una conversacion clara y profesional.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final ChatMessageItem message = _messages[index];
        final bool mine = message.mine;
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: mine ? JobSwipeTheme.primaryIndigo : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(mine ? 18 : 6),
                bottomRight: Radius.circular(mine ? 6 : 18),
              ),
              border: mine ? null : Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: mine ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: mine
                        ? Colors.white.withValues(alpha: 0.75)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: JobSwipeTheme.primaryIndigo,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 52,
            width: 52,
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendMessage,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? value) {
    if (value == null) {
      return 'Ahora';
    }
    final int hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final String minute = value.minute.toString().padLeft(2, '0');
    final String suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}
