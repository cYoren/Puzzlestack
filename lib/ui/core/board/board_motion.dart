import 'package:flutter/animation.dart';

/// The five moves, with the values from PUZZLE_STYLE.md §4.
///
/// The asymmetry is the point: 200ms up, 160ms down. The lift is where the
/// object gains weight and the possible worlds appear; the landing is where it
/// commits. Equal durations read as a toggle, not as a grab.
class BoardMotion {
  const BoardMotion._();

  static const Duration press = Duration(milliseconds: 90);
  static const Duration lift = Duration(milliseconds: 200);
  static const Duration dropZone = Duration(milliseconds: 120);
  static const Duration snap = Duration(milliseconds: 160);
  static const Duration invalid = Duration(milliseconds: 220);
  static const Duration winCell = Duration(milliseconds: 260);
  static const Duration winStagger = Duration(milliseconds: 45);

  /// The longest a whole win cascade may take, however many cells pop.
  static const Duration winCeiling = Duration(milliseconds: 500);

  static const double pressScale = 0.97;
  static const double liftScale = 1.08;

  /// The lifted element rides 12dp above the fingertip, so the finger does not
  /// cover the thing it holds.
  static const double fingerOffset = 12.0;

  /// Visible overshoot: the object has weight.
  static const SpringDescription liftSpring =
      SpringDescription(mass: 1, stiffness: 260, damping: 20);

  /// Decisive, 1–2% overshoot, never bouncy.
  static const SpringDescription snapSpring =
      SpringDescription(mass: 1, stiffness: 500, damping: 30);

  /// Recoil to origin after an illegal drop.
  static const SpringDescription recoilSpring =
      SpringDescription(mass: 1, stiffness: 320, damping: 24);

  static const Curve settle = Curves.easeOut;
  static const Curve win = Curves.easeOutCubic;

  /// Stagger between two popping cells, compressed so a full board still
  /// finishes inside [winCeiling].
  static Duration staggerFor(int count) {
    if (count <= 1) return winStagger;
    final room = winCeiling.inMilliseconds - winCell.inMilliseconds;
    final ms = (room / (count - 1)).floor();
    return Duration(milliseconds: ms.clamp(1, winStagger.inMilliseconds));
  }
}
