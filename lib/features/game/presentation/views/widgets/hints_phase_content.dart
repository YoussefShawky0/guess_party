import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HintsPhaseContent extends StatefulWidget {
  final RoundInfo round;
  final List<Player> players;
  final String gameMode;
  final String currentUserId;

  const HintsPhaseContent({
    super.key,
    required this.round,
    required this.players,
    required this.gameMode,
    required this.currentUserId,
  });

  @override
  State<HintsPhaseContent> createState() => _HintsPhaseContentState();
}

class _HintsPhaseContentState extends State<HintsPhaseContent> {
  final _hintController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context, isTablet),
        SizedBox(height: isTablet ? 12 : 8),
        if (widget.gameMode == 'local')
          _buildLocalModeCard(context, isTablet)
        else ...[
          _buildOnlineModeDescription(context, isTablet),
          SizedBox(height: isTablet ? 20 : 16),
          // السماح بإرسال hints متعددة - دائماً نعرض الـ input
          _buildHintInput(context, isTablet),
          SizedBox(height: isTablet ? 20 : 16),
          _buildHintsList(context, isTablet),
        ],
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet) {
    return Text(
      'Hints Phase',
      style: TextStyle(
        fontSize: isTablet ? 24 : 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildLocalModeCard(BuildContext context, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.hintCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hintCardBorder, width: 2),
      ),
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        children: [
          Icon(
            Icons.people,
            size: isTablet ? 64 : 48,
            color: AppColors.characterCardIcon,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            'Discuss and give hints verbally!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontSize: isTablet ? 20 : 16,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            'Talk about the character without revealing yourself. The timer will move to voting automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: isTablet ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineModeDescription(BuildContext context, bool isTablet) {
    return Text(
      'Give a hint about the character without revealing yourself!',
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: isTablet ? 16 : 14,
      ),
    );
  }

  Widget _buildHintInput(BuildContext context, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _hintController,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: isTablet ? 18 : 16,
            ),
            decoration: InputDecoration(
              labelText: 'Write your hint here',
              labelStyle: TextStyle(color: AppColors.textMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _errorMessage != null
                      ? AppColors.error
                      : AppColors.cardBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _errorMessage != null
                      ? AppColors.error
                      : AppColors.primary,
                  width: 2,
                ),
              ),
              hintText: 'مثال: يستخدم في المطبخ',
              hintStyle: TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surface,
            ),
            maxLines: 2,
            onChanged: (_) {
              if (_errorMessage != null) {
                setState(() => _errorMessage = null);
              }
            },
          ),
          if (_errorMessage != null) ...[
            SizedBox(height: isTablet ? 8 : 6),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: AppColors.error,
                fontSize: isTablet ? 14 : 12,
              ),
            ),
          ],
          SizedBox(height: isTablet ? 16 : 12),
          ElevatedButton.icon(
            onPressed: _submitHint,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
              foregroundColor: AppColors.textPrimary,
              padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(Icons.send, size: isTablet ? 24 : 20),
            label: Text(
              'Send Hint',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitHint() {
    final hint = _hintController.text.trim();

    // Validation
    if (hint.isEmpty) {
      setState(() => _errorMessage = 'Please write a hint first');
      return;
    }
    if (hint.length < 3) {
      setState(() => _errorMessage = 'Hint must be at least 3 characters');
      return;
    }
    if (hint.length > 100) {
      setState(() => _errorMessage = 'Hint is too long (max 100 characters)');
      return;
    }

    setState(() => _errorMessage = null);

    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final cubit = context.read<GameCubit>();
    final state = cubit.state;
    if (state is GameLoaded) {
      final currentPlayer = state.gameState.players.firstWhere(
        (p) => p.userId == currentUserId,
        orElse: () => state.gameState.players.first,
      );

      cubit.sendHint(
        roundId: state.gameState.currentRound.id,
        playerId: currentPlayer.id,
        hint: hint,
      );
      _hintController.clear();
    }
  }

  Widget _buildHintsList(BuildContext context, bool isTablet) {
    if (widget.round.playerHints.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Text(
          'No hints yet...',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: isTablet ? 16 : 14,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hints Submitted (${widget.round.playerHints.length}/${widget.round.playerIds.length})',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: isTablet ? 18 : 16,
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          ...widget.round.playerHints.entries.map((entry) {
            final playerId = entry.key;
            final hint = entry.value;

            final player = widget.players.firstWhere(
              (p) => p.id == playerId,
              orElse: () => widget.players.first,
            );

            return _HintItem(
              playerName: player.username,
              hint: hint ?? 'Hidden hint',
              isTablet: isTablet,
            );
          }),
        ],
      ),
    );
  }
}

class _HintItem extends StatelessWidget {
  final String playerName;
  final String hint;
  final bool isTablet;

  const _HintItem({
    required this.playerName,
    required this.hint,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isTablet ? 12 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(
            FontAwesomeIcons.lightbulb,
            size: isTablet ? 20 : 16,
            color: AppColors.hintIconColor,
          ),
          SizedBox(width: isTablet ? 12 : 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: isTablet ? 16 : 14,
                ),
                children: [
                  TextSpan(
                    text: '$playerName: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: hint),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
