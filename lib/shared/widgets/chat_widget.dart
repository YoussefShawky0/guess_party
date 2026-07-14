import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/di/injection_container.dart';
import 'package:guess_party/features/chat/domain/entities/chat_message.dart';
import 'package:guess_party/features/chat/domain/repositories/chat_repository.dart';
import 'package:guess_party/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:guess_party/features/chat/presentation/cubit/chat_state.dart';

class ChatWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey('chat-$roomId-$roundId'),
      create: (_) =>
          ChatCubit(sl<ChatRepository>())
            ..start(roomId: roomId, roundId: roundId),
      child: _ChatPanel(currentPlayerId: currentPlayerId),
    );
  }
}

class _ChatPanel extends StatefulWidget {
  final String currentPlayerId;

  const _ChatPanel({required this.currentPlayerId});

  @override
  State<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<_ChatPanel> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage(ChatCubit cubit) async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    await cubit.send(content);
    if (!mounted) return;
    final state = cubit.state;
    if (state is ChatLoaded && state.errorMessage == null) {
      _messageController.clear();
    }
  }

  Future<void> _showMessageActions(ChatCubit cubit, ChatMessage message) async {
    final isCurrentUser = message.playerId == widget.currentPlayerId;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isCurrentUser)
              ListTile(
                leading: const Icon(Icons.volume_off),
                title: const Text('Mute this player'),
                onTap: () => Navigator.of(sheetContext).pop('mute'),
              ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Report message'),
              onTap: () => Navigator.of(sheetContext).pop('report'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;

    if (action == 'mute') {
      await cubit.setMuted(playerId: message.playerId, muted: true);
      return;
    }

    final reason = await _askReportReason();
    if (!mounted || reason == null || reason.trim().isEmpty) return;
    await cubit.report(messageId: message.id, reason: reason);
  }

  Future<String?> _askReportReason() async {
    final controller = TextEditingController();
    try {
      return showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Report message'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Tell us what happened',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Submit'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return BlocConsumer<ChatCubit, ChatState>(
      listenWhen: (previous, current) {
        if (current is! ChatLoaded) return false;
        return current.errorMessage != null ||
            (previous is ChatLoaded &&
                current.messages.length > previous.messages.length);
      },
      listener: (context, state) {
        if (state is! ChatLoaded) return;
        if (state.errorMessage != null) {
          final messenger = ScaffoldMessenger.of(context);
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          context.read<ChatCubit>().acknowledgeMessage();
        } else {
          _scrollToBottom();
        }
      },
      builder: (context, state) {
        final cubit = context.read<ChatCubit>();
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
              _ChatHeader(isTablet: isTablet),
              Expanded(child: _buildMessages(context, state, cubit, isTablet)),
              _ChatInput(
                controller: _messageController,
                isSending: state is ChatLoaded && state.isSending,
                onSend: () => _sendMessage(cubit),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessages(
    BuildContext context,
    ChatState state,
    ChatCubit cubit,
    bool isTablet,
  ) {
    if (state is ChatLoading || state is ChatInitial) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (state is ChatFailure) {
      return Center(
        child: Text(
          state.message,
          style: TextStyle(color: AppColors.of(context).textSecondary),
        ),
      );
    }
    final loaded = state as ChatLoaded;
    if (loaded.messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet',
          style: TextStyle(color: AppColors.of(context).textSecondary),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: loaded.messages.length + (loaded.nextCursor == null ? 0 : 1),
      itemBuilder: (context, index) {
        if (loaded.nextCursor != null && index == 0) {
          return Center(
            child: TextButton(
              onPressed: loaded.isLoadingOlder ? null : cubit.loadOlder,
              child: Text(
                loaded.isLoadingOlder ? 'Loading...' : 'Load older messages',
              ),
            ),
          );
        }
        final messageIndex = index - (loaded.nextCursor == null ? 0 : 1);
        final message = loaded.messages[messageIndex];
        final isCurrentUser = message.playerId == widget.currentPlayerId;

        return _MessageBubble(
          message: message,
          isCurrentUser: isCurrentUser,
          isTablet: isTablet,
          onLongPress: () => _showMessageActions(cubit, message),
        );
      },
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final bool isTablet;

  const _ChatHeader({required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _ChatInput({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.of(context).surfaceLight,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(color: AppColors.of(context).textPrimary),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: AppColors.of(context).textMuted),
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
              onSubmitted: (_) => onSend(),
              minLines: 1,
              maxLines: 3,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: isSending ? null : onSend,
            icon: isSending
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
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final bool isTablet;
  final VoidCallback onLongPress;

  const _MessageBubble({
    required this.message,
    required this.isCurrentUser,
    required this.isTablet,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
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
                  message.username,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 13 : 12,
                  ),
                ),
              if (!isCurrentUser) const SizedBox(height: 4),
              Text(
                message.content,
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
