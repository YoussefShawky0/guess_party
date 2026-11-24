import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/design/game_tokens.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/features/stats/domain/badge_summary.dart';
import 'package:guess_party/l10n/l10n.dart';

/// One-line dismissible "Secure your account to keep your stats" banner.
/// The dismissal is remembered per user in [store].
class GuestBanner extends StatefulWidget {
  const GuestBanner({super.key, required this.userId, required this.store});

  final String userId;
  final GuestBannerStore store;

  @override
  State<GuestBanner> createState() => _GuestBannerState();
}

class _GuestBannerState extends State<GuestBanner> {
  // Hidden until the stored choice is known, so it never flashes.
  bool _dismissed = true;

  @override
  void initState() {
    super.initState();
    _loadDismissed();
  }

  Future<void> _loadDismissed() async {
    var dismissed = false;
    try {
      dismissed = await widget.store.isDismissed(widget.userId);
    } catch (_) {
      // Unknown: show it rather than hide the way to secure the account.
    }
    if (!mounted) return;
    setState(() => _dismissed = dismissed);
  }

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    try {
      await widget.store.dismiss(widget.userId);
    } catch (_) {
      // Best effort: it just shows again next time.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final tokens = GameTokens.of(context);
    final colors = AppColors.of(context);

    return Container(
      key: const Key('home-guest-banner'),
      padding: EdgeInsetsDirectional.only(
        start: tokens.spacing.md,
        end: tokens.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(tokens.radius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          const FaIcon(
            FontAwesomeIcons.shieldHalved,
            size: 16,
            color: AppColors.warning,
          ),
          SizedBox(width: tokens.spacing.sm),
          Expanded(
            child: InkWell(
              key: const Key('home-guest-banner-open'),
              onTap: () => context.push(AppRoutes.accountUpgrade),
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  vertical: tokens.spacing.md,
                ),
                child: Text(
                  context.l10n.guestBannerText,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                ),
              ),
            ),
          ),
          IconButton(
            key: const Key('home-guest-banner-dismiss'),
            tooltip: context.l10n.dismiss,
            icon: const Icon(Icons.close, size: 18),
            color: colors.textSecondary,
            onPressed: _dismiss,
          ),
        ],
      ),
    );
  }
}
