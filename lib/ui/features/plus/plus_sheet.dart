import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/posthog.dart';
import '../../../data/purchase/plus_controller.dart';
import '../../../providers/plus_providers.dart';
import '../../../utils/design_system.dart';
import '../../../utils/haptic_feedback.dart';
import '../../../widgets/deck.dart';
import '../../../widgets/tangible.dart';

/// Why the sheet is open. It changes the headline and nothing else, so there is
/// exactly one paywall in the app and it always says the same thing about what
/// Plus is.
enum PlusReason { picks, hints, dailyArchive }

/// The one paywall.
///
/// This is the only place in the app that can start a purchase, opened on the
/// fourth pick or fourth hint of a day, or when opening a past Daily Five. It
/// shows the store's price, never ours, and it can always restore.
///
/// Returns true when Plus is owned by the time it closes, so the caller can
/// carry on with what the player was doing.
Future<bool> showPlusSheet(
  BuildContext context, {
  PlusReason reason = PlusReason.picks,
}) async {
  postHog.capture('paywall_viewed', <String, Object?>{'reason': reason.name});
  final bool? owned = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _PlusSheet(reason: reason),
  );
  if (owned != null) return owned;
  if (!context.mounted) return false;
  return ProviderScope.containerOf(
    context,
    listen: false,
  ).read(plusProvider).ownsPlus;
}

class _PlusSheet extends ConsumerStatefulWidget {
  const _PlusSheet({required this.reason});

  final PlusReason reason;

  @override
  ConsumerState<_PlusSheet> createState() => _PlusSheetState();
}

class _PlusSheetState extends ConsumerState<_PlusSheet> {
  @override
  void initState() {
    super.initState();
    // A cancel from the last time this was open is not this time's news.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(plusProvider.notifier).clearNotice();
      ref.read(plusProvider.notifier).ensurePrice();
    });
  }

  String _headline(PlusState state) {
    if (state.ownsPlus) return 'Plus is yours.';
    switch (widget.reason) {
      case PlusReason.picks:
        return 'Choose any game, any time.';
      case PlusReason.hints:
        return 'Unlimited hints, whenever you want one.';
      case PlusReason.dailyArchive:
        return 'Play any Daily Five in the archive.';
    }
  }

  String _body(PlusState state) {
    if (state.ownsPlus) {
      return 'Unlimited picks, unlimited hints, and every past Daily Five, '
          'on this store account, for good.';
    }
    switch (widget.reason) {
      case PlusReason.picks:
        return 'Three picks and three hints a day are free, along with '
            'today\'s Daily Five. Plus makes picks and hints unlimited and '
            'opens every past Daily Five. One purchase, no subscription.';
      case PlusReason.hints:
        return 'Three hints and three picks a day are free, along with '
            'today\'s Daily Five. Plus makes hints and picks unlimited and '
            'opens every past Daily Five. One purchase, no subscription.';
      case PlusReason.dailyArchive:
        return 'Today\'s Daily Five is free, along with three picks and three '
            'hints a day. Plus opens every past Daily Five and makes picks '
            'and hints unlimited. One purchase, no subscription.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final PlusState state = ref.watch(plusProvider);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color muted = DesignSystem.muted(context);
    final Color accent = DesignSystem.accent(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignSystem.spaceMD,
          0,
          DesignSystem.spaceMD,
          DesignSystem.spaceMD,
        ),
        child: DeckCard(
          padding: const EdgeInsets.fromLTRB(
            DesignSystem.spaceLG,
            DesignSystem.spaceLG,
            DesignSystem.spaceLG,
            DesignSystem.spaceLG,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const DeckMark(size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'PUZZLESTACK PLUS',
                        style: TextStyle(
                          fontFamily: 'Bebas Neue',
                          fontSize: DesignSystem.fontSizeLG,
                          letterSpacing: 1.4,
                          height: 1,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignSystem.spaceMD),
              Text(
                _headline(state),
                style: TextStyle(
                  fontFamily: 'Bebas Neue',
                  fontSize: DesignSystem.fontSize3XL,
                  height: 1,
                  letterSpacing: 0.4,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: DesignSystem.spaceSM),
              Text(
                _body(state),
                style: TextStyle(
                  fontSize: DesignSystem.fontSizeSM,
                  height: 1.45,
                  color: muted,
                ),
              ),
              const SizedBox(height: DesignSystem.spaceLG),
              if (!state.ownsPlus && state.storeReachable) ...[
                _price(context, state, muted),
                const SizedBox(height: DesignSystem.spaceMD),
                _buyButton(context, state, accent),
                const SizedBox(height: DesignSystem.spaceXS),
                _restoreButton(context, state, muted),
              ] else if (!state.ownsPlus)
                Text(
                  'Plus is sold in the App Store and on Google Play.',
                  style: TextStyle(
                    fontSize: DesignSystem.fontSizeSM,
                    height: 1.4,
                    color: muted,
                  ),
                )
              else
                _doneButton(context, accent),
              if (plusNoticeText(state.notice) != null) ...[
                const SizedBox(height: DesignSystem.spaceSM),
                Text(
                  plusNoticeText(state.notice)!,
                  style: TextStyle(
                    fontSize: DesignSystem.fontSizeXS,
                    height: 1.4,
                    color: colors.onSurface,
                  ),
                ),
              ],
              const SizedBox(height: DesignSystem.spaceSM),
              Text(
                'No account, no subscription, nothing collected.',
                style: TextStyle(
                  fontSize: DesignSystem.fontSize2XS,
                  color: muted.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _price(BuildContext context, PlusState state, Color muted) {
    final String? price = state.price;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              price ?? 'Price at checkout',
              style: TextStyle(
                fontFamily: 'Bebas Neue',
                fontSize: price == null
                    ? DesignSystem.fontSizeLG
                    : DesignSystem.fontSize3XL,
                height: 1,
                letterSpacing: 0.4,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
        if (price != null) ...[
          const SizedBox(width: 8),
          Text(
            'one time',
            style: TextStyle(fontSize: DesignSystem.fontSize2XS, color: muted),
          ),
        ],
      ],
    );
  }

  Widget _buyButton(BuildContext context, PlusState state, Color accent) {
    return TangibleContainer(
      width: double.infinity,
      color: accent,
      shadowColor: DesignSystem.primaryShadow,
      onTap: state.busy
          ? null
          : () async {
              HapticFeedbackUtil.mediumImpact();
              final PlusNotice notice =
                  await ref.read(plusProvider.notifier).buy();
              if (!context.mounted) return;
              if (notice == PlusNotice.purchased ||
                  notice == PlusNotice.alreadyOwned) {
                Navigator.of(context).pop(true);
              }
            },
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: state.busy
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: DesignSystem.onAccent(context),
                ),
              )
            : Text(
                'GET PLUS',
                style: TextStyle(
                  fontFamily: 'Bebas Neue',
                  fontSize: DesignSystem.fontSizeLG,
                  letterSpacing: 1.2,
                  height: 1,
                  color: DesignSystem.onAccent(context),
                ),
              ),
      ),
    );
  }

  Widget _restoreButton(BuildContext context, PlusState state, Color muted) {
    return Center(
      child: TextButton(
        onPressed: state.busy
            ? null
            : () async {
                final PlusNotice notice =
                    await ref.read(plusProvider.notifier).restore();
                if (!context.mounted) return;
                if (notice == PlusNotice.restored) {
                  Navigator.of(context).pop(true);
                }
              },
        child: Text(
          'Restore purchase',
          style: TextStyle(
            fontSize: DesignSystem.fontSizeXS,
            fontWeight: FontWeight.w600,
            color: muted,
          ),
        ),
      ),
    );
  }

  Widget _doneButton(BuildContext context, Color accent) {
    return TangibleContainer(
      width: double.infinity,
      color: accent,
      shadowColor: DesignSystem.primaryShadow,
      onTap: () => Navigator.of(context).pop(true),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(
          'PLAY',
          style: TextStyle(
            fontFamily: 'Bebas Neue',
            fontSize: DesignSystem.fontSizeLG,
            letterSpacing: 1.2,
            height: 1,
            color: DesignSystem.onAccent(context),
          ),
        ),
      ),
    );
  }
}

/// The one sentence a notice deserves, or null when there is nothing to say.
///
/// Kept next to the sheet rather than in the controller: the controller reports
/// what the store answered, and the words are a UI concern.
String? plusNoticeText(PlusNotice notice) {
  switch (notice) {
    case PlusNotice.none:
      return null;
    case PlusNotice.purchased:
      return 'Thank you. Plus is yours.';
    case PlusNotice.alreadyOwned:
      return 'This account already owned Plus. It is now on this device.';
    case PlusNotice.cancelled:
      return 'Cancelled. You were not charged.';
    case PlusNotice.pending:
      return 'The store is still processing this. Plus appears here as soon as '
          'it completes.';
    case PlusNotice.restored:
      return 'Restored. Plus is on this device.';
    case PlusNotice.nothingToRestore:
      return 'The store found no purchase to restore.';
    case PlusNotice.revoked:
      return 'The store no longer lists this purchase, so Plus is off.';
    case PlusNotice.unavailable:
      return 'This store is not available on this device.';
    case PlusNotice.failed:
      return 'Could not reach the store. Nothing was changed; try again.';
  }
}

/// The settings row: what this device owns, and the way to get it back.
///
/// No buy button here. The paywall appears in one place (the fourth pick of a
/// day); restore is support, not a sale, and belongs where a player who changed
/// phone will look for it.
class PlusSettingsRow extends ConsumerWidget {
  const PlusSettingsRow({super.key});

  static const int freePicksPerDay = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlusState state = ref.watch(plusProvider);
    final Color muted = DesignSystem.muted(context);

    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.workspace_premium_outlined, size: 20, color: muted),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Puzzlestack Plus',
                    style: TextStyle(
                      fontSize: DesignSystem.fontSizeMD,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    state.ownsPlus
                        ? 'Owned: unlimited picks, hints, and Daily Five archive'
                        : '$freePicksPerDay free picks and hints a day',
                    style: TextStyle(
                      fontSize: DesignSystem.fontSize2XS,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: state.busy
                  ? null
                  : () async {
                      final PlusNotice notice =
                          await ref.read(plusProvider.notifier).restore();
                      if (!context.mounted) return;
                      final String message =
                          plusNoticeText(notice) ?? 'Plus is on this device.';
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text(message),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                    },
              child: Text(
                state.ownsPlus ? 'VERIFY' : 'RESTORE',
                style: TextStyle(
                  fontFamily: 'Bebas Neue',
                  fontSize: DesignSystem.fontSizeMD,
                  letterSpacing: 1.1,
                  color: DesignSystem.accent(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
