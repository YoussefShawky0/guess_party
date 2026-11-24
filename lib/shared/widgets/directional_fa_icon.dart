import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// A [FaIcon] that mirrors in right-to-left locales.
///
/// Material's `Icons.arrow_back` etc. mirror on their own
/// (`matchTextDirection`), but Font Awesome glyphs never do. Use this for
/// icons whose meaning is a direction (back, next, chevrons, send, sign out),
/// not for icons with a fixed real-world orientation (play, share, clocks).
class DirectionalFaIcon extends StatelessWidget {
  const DirectionalFaIcon(this.icon, {super.key, this.size, this.color});

  final FaIconData icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Transform.flip(
      flipX: isRtl,
      child: FaIcon(icon, size: size, color: color),
    );
  }
}
