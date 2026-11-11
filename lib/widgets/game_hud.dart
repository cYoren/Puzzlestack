import 'package:flutter/material.dart';

import '../utils/design_system.dart';

/// The strip of stat chips that sits above a board: score, timer, trial count.
///
/// It is a [Wrap], not a [Row], and that is the whole point. A `Row` gives each
/// chip its intrinsic width and then overflows when the total does not fit, so
/// two chips that read fine at 390dp drew a yellow-and-black stripe at 320dp in
/// about fifty games. A [Wrap] puts the second chip on its own line instead.
///
/// On one line it looks exactly like the `Row(mainAxisAlignment: spaceBetween)`
/// it replaces: first chip at the leading edge, last at the trailing edge.
///
/// Do not put [Expanded] or [Flexible] children in here — a [Wrap] has no flex.
/// Chips are intrinsic-width by design; if a chip is too wide on its own, make
/// its label shorter rather than stretching it.
class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.children,
    this.alignment = WrapAlignment.spaceBetween,
    this.spacing = DesignSystem.spaceSM,
    this.runSpacing = DesignSystem.spaceXS,
  });

  final List<Widget> children;
  final WrapAlignment alignment;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    // A [Wrap] shrink-wraps to its widest run, where the [Row] it replaces
    // stretched to the full width. Without the full-width box the chips would
    // bunch in the middle of the screen instead of sitting at the two edges.
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: alignment,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: spacing,
        runSpacing: runSpacing,
        children: children,
      ),
    );
  }
}
