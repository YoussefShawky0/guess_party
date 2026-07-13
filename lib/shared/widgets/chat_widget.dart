import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/di/injection_container.dart';
import 'package:guess_party/features/chat/domain/repositories/chat_repository.dart';
import 'dart:async';

class ChatWidget extends StatefulWidget {
  final String roomId;
  final String roundId;
  final String currentPlayerId;

  const ChatWidget({
    super.key,
    required this.roomId,
    required this.roundId,
    required this.currentPlayerId,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatRepository _repository;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  @override
  void initState() {
    super.initState();
    _repository = sl<ChatRepository>();
    _loadMessages();
    _subscribeToMessages();
  }

  @override
  void didUpdateWidget(covariant ChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roundId != widget.roundId ||
        oldWidget.roomId != widget.roomId) {
      _subscription?.cancel();
      _messages = [];
      _isLoading = true;
      _loadMessages();
      _subscribeToMessages();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final response = await _repository.getMessages(
        roomId: widget.roomId,
        roundId: widget.roundId,
      );

      if (!mounted) return;
      setState(() {
        _messages = List<Map<String, dynamic>>.from(response);
        _sortMessages();
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _subscribeToMessages() {
    try {
      _subscription?.cancel();
      _subscription = _repository
          .watchMessages(roomId: widget.roomId, roundId: widget.roundId)
          .listen((messages) {
            if (!mounted) return;
            setState(() {
              _messages = messages;
              _sortMessages();
              _isLoading = false;
            });
            _scrollToBottom();
          });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sortMessages() {
    _messages.sort((a, b) {
      final aCreatedAt = DateTime.tryParse(a['created_at']?.toString() ?? '');
      final bCreatedAt = DateTime.tryParse(b['created_at']?.toString() ?? '');
      if (aCreatedAt == null && bCreatedAt == null) return 0;
      if (aCreatedAt == null) return -1;
      if (bCreatedAt == null) return 1;
      return aCreatedAt.compareTo(bCreatedAt);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;

    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    if (content.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message must be 500 characters or less')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await _repository.sendMessage(
        roomId: widget.roomId,
        roundId: widget.roundId,
        playerId: widget.currentPlayerId,
        content: content,
      );

      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Container(
      height: isTablet ? 400 : 300,
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.of(context).surfaceLight.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.comments,
                  color: AppColors.primary,
                  size: isTablet ? 20 : 16,
                ),
                const SizedBox(width: 12),
                Text(
                  'Chat',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 18 : 16,
                    color: AppColors.of(context).textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(
                        color: AppColors.of(context).textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isCurrentUser =
                          message['player_id'] == widget.currentPlayerId;
                      final players = message['players'];
                      final username = players is Map<String, dynamic>
                          ? players['username'] as String? ?? 'Player'
                          : 'Player';

                      return _MessageBubble(
                        content: message['content']?.toString() ?? '',
                        username: username,
                        isCurrentUser: isCurrentUser,
                        isTablet: isTablet,
                      );
                    },
                  ),
          ),

          // Input Field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.of(context).surfaceLight,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: AppColors.of(context).textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(
                        color: AppColors.of(context).textMuted,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.of(context).surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    minLines: 1,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _isSending ? null : _sendMessage,
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const FaIcon(FontAwesomeIcons.paperPlane, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.of(context).textPrimary,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String content;
  final String username;
  final bool isCurrentUser;
  final bool isTablet;

  const _MessageBubble({
    required this.content,
    required this.username,
    required this.isCurrentUser,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? AppColors.primary
              : AppColors.of(context).surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isCurrentUser)
              Text(
                username,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 13 : 12,
                ),
              ),
            if (!isCurrentUser) const SizedBox(height: 4),
            Text(
              content,
              style: TextStyle(
                color: isCurrentUser
                    ? AppColors.of(context).textPrimary
                    : AppColors.of(context).textPrimary,
                fontSize: isTablet ? 16 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
