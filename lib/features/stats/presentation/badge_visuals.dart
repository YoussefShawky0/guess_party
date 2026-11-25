import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/features/stats/domain/badges.dart';
import 'package:guess_party/l10n/app_localizations.dart';

extension BadgeVisuals on BadgeId {
  FaIconData get icon => switch (this) {
    BadgeId.firstGame => FontAwesomeIcons.flag,
    BadgeId.regular => FontAwesomeIcons.gamepad,
    BadgeId.veteran => FontAwesomeIcons.medal,
    BadgeId.champion => FontAwesomeIcons.trophy,
    BadgeId.masterOfDisguise => FontAwesomeIcons.userSecret,
    BadgeId.detective => FontAwesomeIcons.magnifyingGlass,
  };

  String localizedName(AppLocalizations l10n) => switch (this) {
    BadgeId.firstGame => l10n.badgeFirstGameName,
    BadgeId.regular => l10n.badgeRegularName,
    BadgeId.veteran => l10n.badgeVeteranName,
    BadgeId.champion => l10n.badgeChampionName,
    BadgeId.masterOfDisguise => l10n.badgeMasterOfDisguiseName,
    BadgeId.detective => l10n.badgeDetectiveName,
  };

  String localizedDescription(AppLocalizations l10n) => switch (this) {
    BadgeId.firstGame => l10n.badgeFirstGameDescription,
    BadgeId.regular => l10n.badgeRegularDescription,
    BadgeId.veteran => l10n.badgeVeteranDescription,
    BadgeId.champion => l10n.badgeChampionDescription,
    BadgeId.masterOfDisguise => l10n.badgeMasterOfDisguiseDescription,
    BadgeId.detective => l10n.badgeDetectiveDescription,
  };
}
