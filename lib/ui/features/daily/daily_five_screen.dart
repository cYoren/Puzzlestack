import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/daily/daily_five.dart';
import '../../../data/game_categories.dart';
import '../../../data/game_guides.dart';
import '../../../data/game_metadata.dart';
import '../../../data/picks/pick_ledger.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/daily_five_providers.dart';
import '../../../providers/game_tier_provider.dart';
import '../../../providers/pick_providers.dart';
import '../../../providers/plus_providers.dart';
import '../../../providers/user_providers.dart';
import '../../../utils/design_system.dart';
import '../../../utils/game_clock.dart';
import '../../../utils/haptic_feedback.dart';
import '../../../widgets/deck.dart';
import '../../../widgets/game_guide_screen.dart';
import '../../../widgets/tangible.dart';
import '../../core/assist/game_assist.dart';
import '../../core/assist/hint_request.dart';
import '../../core/juice/game_scope.dart';
import '../feed/feed_session.dart';
import '../plus/plus_sheet.dart';

/// Five seeded puzzles, the same for everyone on a given date (`docs/FEED.md`).
///
/// Today's Daily Five is free for every player. Opening any past day in the
/// archive checks Plus and opens the Plus sheet when Plus is not owned yet.
class DailyFiveScreen extends ConsumerStatefulWidget {
  const DailyFiveScreen({super.key, this.initialDayKey});

  final String? initialDayKey;

  @override
  ConsumerState<DailyFiveScreen> createState() => _DailyFiveScreenState();
}

class _DailyFiveScreenState extends ConsumerState<DailyFiveScreen> {
  late String _dayKey;
  int _slot = 0;
  int _restartEpoch = 0;
  FeedSession? _session;
  ProviderContainer? _slotContainer;
  String? _slotContainerKey;

  @override
  void initState() {
    super.initState();
    final DateTime now = ref.read(dailyFiveClockProvider)();
    _dayKey = widget.initialDayKey ?? pickDayKey(now);
    _slot = _firstOpenSlot(_dayKey);
    _activateSession();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(dailyFiveProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _slotContainer?.dispose();
    _slotContainer = null;
    final FeedSession? session = _session;
    if (session != null) FeedSession.deactivate(session);
    super.dispose();
  }

  ProviderContainer _ensureSlotContainer(String gameId) {
    final String wantedKey = '$_dayKey:$_slot:$gameId:$_restartEpoch';
    if (_slotContainer != null && _slotContainerKey == wantedKey) {
      return _slotContainer!;
    }
    final ProviderContainer? old = _slotContainer;
    if (old != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
    final ProviderContainer fresh = ProviderContainer(
      overrides: <Override>[
        userRepositoryProvider
            .overrideWithValue(ref.read(userRepositoryProvider)),
        pickStoreProvider.overrideWithValue(ref.read(pickStoreProvider)),
        plusStoreProvider.overrideWithValue(ref.read(plusStoreProvider)),
        plusGatewayProvider.overrideWithValue(ref.read(plusGatewayProvider)),
        gameTierStoreProvider
            .overrideWithValue(ref.read(gameTierStoreProvider)),
        dailyFiveClockProvider
            .overrideWithValue(ref.read(dailyFiveClockProvider)),
      ],
    );
    _slotContainer = fresh;
    _slotContainerKey = wantedKey;
    return fresh;
  }

  int _firstOpenSlot(String dayKey) {
    final DailyFiveProgress progress =
        ref.read(dailyFiveProvider).progressFor(dayKey);
    for (int i = 0; i < 5; i++) {
      if (!progress.timesMs.containsKey(i)) return i;
    }
    return 0;
  }

  void _activateSession() {
    final FeedSession? previous = _session;
    if (previous != null) FeedSession.deactivate(previous);
    final FeedSession nextSession = FeedSession(
      next: _advanceSlot,
      restart: _restartSlot,
      close: () => Navigator.of(context).maybePop(),
      isRoute: true,
      fixedFeedSize: true,
      seedFor: (String gameId) => dailySeedFor(_dayKey, _slot, gameId),
      onSolved: _recordCurrentSolve,
    );
    _session = nextSession;
    FeedSession.activate(nextSession);
  }

  void _recordCurrentSolve(String? detail) {
    final List<String> hand = _handForDay(context);
    if (_slot < 0 || _slot >= hand.length) return;
    final String gameId = hand[_slot];
    final int elapsedMs = (GameClock.elapsed(gameId)?.inMilliseconds ?? 1000)
        .clamp(1000, 3600000);
    ref.read(dailyFiveProvider.notifier).recordSlot(
          dayKey: _dayKey,
          slot: _slot,
          elapsedMs: elapsedMs,
          badge: detail,
        );
  }

  void _advanceSlot() {
    if (!mounted) return;
    final DailyFiveProgress progress =
        ref.read(dailyFiveProvider).progressFor(_dayKey);
    if (!progress.timesMs.containsKey(_slot)) {
      _recordCurrentSolve(null);
    }
    final DailyFiveProgress after =
        ref.read(dailyFiveProvider).progressFor(_dayKey);
    if (after.isComplete) {
      setState(() {});
      return;
    }
    for (int step = 1; step <= 5; step++) {
      final int candidate = (_slot + step) % 5;
      if (!after.timesMs.containsKey(candidate)) {
        setState(() {
          _slot = candidate;
          _restartEpoch += 1;
        });
        return;
      }
    }
  }

  void _restartSlot() {
    if (!mounted) return;
    HapticFeedbackUtil.mediumImpact();
    setState(() => _restartEpoch += 1);
  }

  List<String> _handForDay(BuildContext context) {
    final String locale =
        Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    return dailyFiveForDate(_dayKey, localeCode: locale);
  }

  Future<void> _selectDay(String targetDayKey) async {
    ref.read(dailyFiveProvider.notifier).refresh();
    final String todayKey = pickDayKey(ref.read(dailyFiveClockProvider)());
    if (targetDayKey != todayKey && !ref.read(plusProvider).ownsPlus) {
      final bool unlocked = await showPlusSheet(
        context,
        reason: PlusReason.dailyArchive,
      );
      if (!mounted || !unlocked) return;
    }
    setState(() {
      _dayKey = targetDayKey;
      _slot = _firstOpenSlot(targetDayKey);
      _restartEpoch += 1;
    });
  }

  Future<void> _openArchiveSheet() async {
    final DateTime now = ref.read(dailyFiveClockProvider)();
    final DateTime todayFloor = DateTime(now.year, now.month, now.day);
    final List<String> recentDays = <String>[
      for (int d = 0; d < 14; d++)
        pickDayKey(todayFloor.subtract(Duration(days: d))),
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Consumer(
          builder: (BuildContext context, WidgetRef ref, _) {
            final DailyFiveSummaryState summary = ref.watch(dailyFiveProvider);
            final bool ownsPlus = ref.watch(plusProvider).ownsPlus;
            final Color muted = DesignSystem.muted(context);
            final Color accent = DesignSystem.accent(context);
            final ColorScheme colors = Theme.of(context).colorScheme;

            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(DesignSystem.spaceMD),
                child: DeckCard(
                  padding: const EdgeInsets.all(DesignSystem.spaceLG),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 460),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'DAILY FIVE ARCHIVE',
                                  style: TextStyle(
                                    fontFamily: 'Bebas Neue',
                                    fontSize: DesignSystem.fontSize2XL,
                                    letterSpacing: 1.2,
                                    height: 1,
                                    color: colors.onSurface,
                                  ),
                                ),
                              ),
                            ),
                            if (!ownsPlus) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'PAST DAYS ARE PLUS',
                                    style: TextStyle(
                                      fontFamily: 'Bebas Neue',
                                      fontSize: DesignSystem.fontSizeSM,
                                      letterSpacing: 1.0,
                                      color: accent,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: DesignSystem.spaceSM),
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: recentDays.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: DesignSystem.hairline(context),
                            ),
                            itemBuilder: (BuildContext context, int index) {
                              final String key = recentDays[index];
                              final bool isToday =
                                  key == pickDayKey(todayFloor);
                              final DailyFiveProgress prog =
                                  summary.progressFor(key);
                              final bool selected = key == _dayKey;
                              return InkWell(
                                key: ValueKey<String>('daily_archive_$key'),
                                onTap: () async {
                                  Navigator.of(sheetContext).pop();
                                  await _selectDay(key);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          isToday
                                              ? 'Today (${formatDailyDateLabel(key)})'
                                              : formatDailyDateLabel(key),
                                          style: TextStyle(
                                            fontSize: DesignSystem.fontSizeMD,
                                            fontWeight: selected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: colors.onSurface,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        prog.isComplete
                                            ? 'Done ${formatDailyDuration(prog.totalMs)}'
                                            : (isToday || ownsPlus
                                                ? '${prog.solvedCount} / 5'
                                                : 'PLUS'),
                                        style: TextStyle(
                                          fontFamily: 'Bebas Neue',
                                          fontSize: DesignSystem.fontSizeMD,
                                          letterSpacing: 1.0,
                                          color:
                                              prog.isComplete ? accent : muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final DailyFiveSummaryState summary = ref.watch(dailyFiveProvider);
    final String liveTodayKey = pickDayKey(ref.read(dailyFiveClockProvider)());
    final bool ownsPlus = ref.watch(plusProvider).ownsPlus;
    final bool isPastDay = _dayKey != liveTodayKey;
    final DailyFiveProgress progress = summary.progressFor(_dayKey);
    final List<String> handIds = _handForDay(context);
    final Color bed = DesignSystem.paperOf(context);
    final Color muted = DesignSystem.muted(context);
    final Color accent = DesignSystem.accent(context);
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: bed,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                _topBar(context, summary, muted, accent, colors),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignSystem.spaceMD,
                      DesignSystem.spaceXS,
                      DesignSystem.spaceMD,
                      DesignSystem.spaceMD,
                    ),
                    child: isPastDay && !ownsPlus
                        ? _archiveGateCard(context, muted, accent, colors)
                        : progress.isComplete
                            ? _completedCard(
                                context,
                                handIds,
                                progress,
                                summary.streak,
                                muted,
                                accent,
                                colors,
                              )
                            : _activeSlotCard(
                                context,
                                handIds,
                                progress,
                                muted,
                                accent,
                                colors,
                              ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(
    BuildContext context,
    DailyFiveSummaryState summary,
    Color muted,
    Color accent,
    ColorScheme colors,
  ) {
    return SizedBox(
      height: kToolbarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spaceSM),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              color: colors.onSurface,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'DAILY FIVE',
                      style: TextStyle(
                        fontFamily: 'Bebas Neue',
                        fontSize: DesignSystem.fontSizeXL,
                        letterSpacing: 1.3,
                        height: 1,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatDailyDateLabel(_dayKey).toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Bebas Neue',
                        fontSize: DesignSystem.fontSizeMD,
                        letterSpacing: 1.1,
                        height: 1,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (summary.streak > 0)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  '${summary.streak}D STREAK',
                  style: TextStyle(
                    fontFamily: 'Bebas Neue',
                    fontSize: DesignSystem.fontSizeMD,
                    letterSpacing: 1.0,
                    color: accent,
                  ),
                ),
              ),
            TextButton(
              key: const ValueKey<String>('daily_five_archive_button'),
              onPressed: _openArchiveSheet,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'ARCHIVE',
                  style: TextStyle(
                    fontFamily: 'Bebas Neue',
                    fontSize: DesignSystem.fontSizeMD,
                    letterSpacing: 1.1,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _archiveGateCard(
    BuildContext context,
    Color muted,
    Color accent,
    ColorScheme colors,
  ) {
    return Center(
      child: DeckCard(
        padding: const EdgeInsets.all(DesignSystem.spaceLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatDailyDateLabel(_dayKey).toUpperCase(),
              style: TextStyle(
                fontFamily: 'Bebas Neue',
                fontSize: DesignSystem.fontSizeLG,
                letterSpacing: 1.2,
                color: muted,
              ),
            ),
            const SizedBox(height: DesignSystem.spaceXS),
            Text(
              'Play any Daily Five in the archive.',
              style: TextStyle(
                fontFamily: 'Bebas Neue',
                fontSize: DesignSystem.fontSize3XL,
                height: 1,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: DesignSystem.spaceSM),
            Text(
              'Today\'s Daily Five is free for everyone. Plus opens every past '
              'Daily Five, along with unlimited Stack picks and hints.',
              style: TextStyle(
                fontSize: DesignSystem.fontSizeSM,
                height: 1.45,
                color: muted,
              ),
            ),
            const SizedBox(height: DesignSystem.spaceLG),
            TangibleContainer(
              width: double.infinity,
              color: accent,
              shadowColor: DesignSystem.primaryShadow,
              padding: const EdgeInsets.symmetric(vertical: 14),
              onTap: () => showPlusSheet(
                context,
                reason: PlusReason.dailyArchive,
              ),
              child: Center(
                child: Text(
                  'UNLOCK ARCHIVE WITH PLUS',
                  style: TextStyle(
                    fontFamily: 'Bebas Neue',
                    fontSize: DesignSystem.fontSizeLG,
                    letterSpacing: 1.2,
                    color: DesignSystem.onAccent(context),
                  ),
                ),
              ),
            ),
            const SizedBox(height: DesignSystem.spaceXS),
            Center(
              child: TextButton(
                onPressed: () => _selectDay(
                  pickDayKey(ref.read(dailyFiveClockProvider)()),
                ),
                child: Text(
                  'Play today\'s free Daily Five',
                  style: TextStyle(
                      fontSize: DesignSystem.fontSizeXS, color: muted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeSlotCard(
    BuildContext context,
    List<String> handIds,
    DailyFiveProgress progress,
    Color muted,
    Color accent,
    ColorScheme colors,
  ) {
    final String gameId = handIds[_slot];
    final GameMetadata? game = GameFeed.find(gameId);
    if (game == null) return const SizedBox.shrink();
    final ProviderContainer slotContainer = _ensureSlotContainer(game.id);
    final BuildContext rootScreenContext = this.context;
    final WidgetRef rootRef = ref;

    return UncontrolledProviderScope(
      key: ValueKey<String>(
        'daily_scope_${_dayKey}_${_slot}_${game.id}_$_restartEpoch',
      ),
      container: slotContainer,
      child: Consumer(
        builder: (BuildContext slotContext, WidgetRef slotRef, _) {
          final GameAssistActions? assist = gameAssistFor(game.id, slotRef);
          return DeckCard(
            clip: true,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: DesignSystem.hairline(context)),
                    ),
                  ),
                  child: Row(
                    children: [
                      for (int i = 0; i < 5; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _slot = i;
                              _restartEpoch += 1;
                            }),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(99),
                                color: progress.timesMs.containsKey(i)
                                    ? accent
                                    : (i == _slot
                                        ? colors.onSurface
                                        : DesignSystem.hairline(context)),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 12),
                      Text(
                        '${_slot + 1} / 5',
                        style: TextStyle(
                          fontFamily: 'Bebas Neue',
                          fontSize: DesignSystem.fontSizeSM + 2,
                          letterSpacing: 1.1,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      game.subtitleGetter(slotContext),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: DesignSystem.fontSizeXS,
                        color: muted,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignSystem.spaceSM,
                    ),
                    child: GameScope(
                      gameId: game.id,
                      child: game.builder(slotContext),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: DesignSystem.hairline(context)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          game.titleGetter(slotContext),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Bebas Neue',
                            fontSize: DesignSystem.fontSize2XL,
                            height: 1,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      if (assist?.onHint != null)
                        IconButton(
                          tooltip: 'Hint',
                          icon: Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 20,
                            color: muted,
                          ),
                          onPressed: () => requestHint(
                            rootScreenContext,
                            rootRef,
                            assist!.onHint!,
                          ),
                        ),
                      IconButton(
                        tooltip: AppLocalizations.of(context)?.restartPuzzle ??
                            'Restart',
                        icon:
                            Icon(Icons.refresh_rounded, size: 20, color: muted),
                        onPressed: _restartSlot,
                      ),
                      if (gameGuides.containsKey(game.id))
                        IconButton(
                          tooltip: AppLocalizations.of(context)?.howToPlay ??
                              'How to Play',
                          icon: Icon(Icons.help_outline_rounded,
                              size: 20, color: muted),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => GameGuideScreen(
                                gameId: game.id,
                                gameColor: accent,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _completedCard(
    BuildContext context,
    List<String> handIds,
    DailyFiveProgress progress,
    int streak,
    Color muted,
    Color accent,
    ColorScheme colors,
  ) {
    final List<DailySlotResult> results = <DailySlotResult>[
      for (int i = 0; i < handIds.length; i++)
        DailySlotResult(
          gameId: handIds[i],
          title: GameFeed.find(handIds[i])?.titleGetter(context) ?? handIds[i],
          elapsedMs: progress.timesMs[i] ?? 1000,
          badge: progress.badges[i],
        ),
    ];
    final String shareText = formatDailyFiveShare(
      dayKey: _dayKey,
      results: results,
    );

    return Center(
      child: DeckCard(
        padding: const EdgeInsets.all(DesignSystem.spaceLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'DAILY FIVE COMPLETE',
                  style: TextStyle(
                    fontFamily: 'Bebas Neue',
                    fontSize: DesignSystem.fontSize2XL,
                    letterSpacing: 1.2,
                    color: colors.onSurface,
                  ),
                ),
                const Spacer(),
                if (streak > 0)
                  Text(
                    '$streak DAY STREAK',
                    style: TextStyle(
                      fontFamily: 'Bebas Neue',
                      fontSize: DesignSystem.fontSizeLG,
                      letterSpacing: 1.0,
                      color: accent,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: DesignSystem.spaceMD),
            for (final DailySlotResult r in results)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.title,
                        style: TextStyle(
                          fontSize: DesignSystem.fontSizeMD,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      r.badge ?? formatDailyDuration(r.elapsedMs),
                      style: TextStyle(
                        fontFamily: 'Bebas Neue',
                        fontSize: DesignSystem.fontSizeLG,
                        letterSpacing: 0.8,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
            Divider(height: 24, color: DesignSystem.hairline(context)),
            Row(
              children: [
                Text(
                  'TOTAL',
                  style: TextStyle(
                    fontFamily: 'Bebas Neue',
                    fontSize: DesignSystem.fontSizeXL,
                    letterSpacing: 1.1,
                    color: colors.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  formatDailyDuration(progress.totalMs),
                  style: TextStyle(
                    fontFamily: 'Bebas Neue',
                    fontSize: DesignSystem.fontSize2XL,
                    letterSpacing: 1.0,
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignSystem.spaceLG),
            TangibleContainer(
              key: const ValueKey<String>('daily_five_share_button'),
              width: double.infinity,
              color: accent,
              shadowColor: DesignSystem.primaryShadow,
              padding: const EdgeInsets.symmetric(vertical: 14),
              onTap: () async {
                HapticFeedbackUtil.selectionClick();
                await Clipboard.setData(ClipboardData(text: shareText));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('Copied Daily Five summary to clipboard.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
              },
              child: Center(
                child: Text(
                  'SHAREPLAIN TEXT'.replaceFirst('SHAREPLAIN', 'SHARE PLAIN'),
                  style: TextStyle(
                    fontFamily: 'Bebas Neue',
                    fontSize: DesignSystem.fontSizeLG,
                    letterSpacing: 1.2,
                    color: DesignSystem.onAccent(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
