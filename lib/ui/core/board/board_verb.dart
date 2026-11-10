import '../../../utils/haptic_feedback.dart';

/// The five verbs. Puzzles emit these and never touch `HapticFeedback`
/// directly, so sound (when it exists) maps to the same five events.
enum BoardVerb {
  /// Touched something.
  select,

  /// A mark landed.
  place,

  /// That move is illegal.
  invalid,

  /// Puzzle finished.
  solve,

  /// A drag began.
  lift,
}

void emitVerb(BoardVerb verb) {
  switch (verb) {
    case BoardVerb.select:
      HapticFeedbackUtil.selectionClick();
    case BoardVerb.place:
      HapticFeedbackUtil.mediumImpact();
    case BoardVerb.invalid:
      HapticFeedbackUtil.heavyImpact();
    case BoardVerb.solve:
      HapticFeedbackUtil.victory();
    case BoardVerb.lift:
      HapticFeedbackUtil.lightImpact();
  }
}
