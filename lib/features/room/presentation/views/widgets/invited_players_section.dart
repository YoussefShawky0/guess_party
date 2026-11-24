import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/features/room/domain/entities/room_invite.dart';
import 'package:guess_party/features/room/presentation/cubit/room_invites_cubit.dart';
import 'package:guess_party/l10n/l10n.dart';

/// Host-only list of rematch invites with their status. Renders nothing for
/// an empty list.
class InvitedPlayersSection extends StatelessWidget {
  final List<RoomInvite> invites;

  const InvitedPlayersSection({super.key, required this.invites});

  @override
  Widget build(BuildContext context) {
    if (invites.isEmpty) return const SizedBox.shrink();
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 16),
      child: Container(
        key: const Key('invited-players-section'),
        padding: const EdgeInsetsDirectional.all(12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.invitedPlayers,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 140),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: invites.length,
                itemBuilder: (context, i) => _InviteRow(invite: invites[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteRow extends StatelessWidget {
  final RoomInvite invite;

  const _InviteRow({required this.invite});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final (label, color) = switch (invite.status) {
      RoomInviteStatus.accepted => (
        context.l10n.inviteStatusAccepted,
        AppColors.success,
      ),
      RoomInviteStatus.pending => (
        context.l10n.inviteStatusPending,
        colors.textMuted,
      ),
      RoomInviteStatus.declined => (
        context.l10n.inviteStatusDeclined,
        AppColors.error,
      ),
    };

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              invite.username,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Binds [InvitedPlayersSection] to the ambient [RoomInvitesCubit]; renders
/// nothing when none is provided.
class InvitedPlayersScope extends StatelessWidget {
  const InvitedPlayersScope({super.key});

  @override
  Widget build(BuildContext context) {
    final RoomInvitesCubit cubit;
    try {
      cubit = context.read<RoomInvitesCubit>();
    } on ProviderNotFoundException {
      return const SizedBox.shrink();
    }
    return BlocBuilder<RoomInvitesCubit, List<RoomInvite>>(
      bloc: cubit,
      builder: (_, invites) => InvitedPlayersSection(invites: invites),
    );
  }
}
