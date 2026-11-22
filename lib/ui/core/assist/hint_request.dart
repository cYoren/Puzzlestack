import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/posthog.dart';
import '../../../data/picks/hint_gate.dart';
import '../../../providers/pick_providers.dart';
import '../../features/plus/plus_sheet.dart';

/// Runs [onHint] if today's free hint allowance or Plus permits it, and opens
/// the Plus sheet on the fourth hint of a day.
///
/// Returns true when [onHint] actually ran.
Future<bool> requestHint(
  BuildContext context,
  WidgetRef ref,
  VoidCallback onHint,
) async {
  final HintGate gate = ref.read(hintGateProvider);
  HintDecision decision = await gate.preview();
  if (!context.mounted) return false;

  if (decision is HintRefused) {
    final bool owned = await showPlusSheet(context, reason: PlusReason.hints);
    if (!context.mounted || !owned) return false;
    decision = await gate.preview();
    if (!context.mounted || decision is HintRefused) return false;
  }

  await gate.commit(decision);
  if (!context.mounted) return false;
  postHog.boardHinted();
  onHint();
  return true;
}
