import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../widgets/deck.dart';
import '../../../providers/user_providers.dart';
import '../../../utils/design_system.dart';
import '../feed/feed_screen.dart';
import '../home/discovery_home_screen.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';

/// Three rooms, in the order a player uses them: the puzzle in front of you,
/// the whole stack, and what you have done so far.
///
/// Settings is not a room. It lives behind the gear in the stack, where a
/// preference belongs, instead of taking a third of the bottom bar away from
/// the two things anyone opens this app for.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  /// Opens on the deal. The first thing you see is a puzzle.
  int _selectedIndex = 0;

  /// Tabs are built the first time they are opened and kept alive after that,
  /// so the deal keeps its card and the stack keeps its scroll position without
  /// starting three screens' worth of timers at launch.
  final Set<int> _visited = {0};

  Timer? _dayCheckTimer;
  DateTime? _lastCheckedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameStreakNotifierProvider.notifier).refreshStatus();
    });
    _lastCheckedDate = DateTime.now();
    _dayCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkDayChange();
    });
  }

  /// The streak resets at local midnight, so a session left open overnight must
  /// re-read it rather than trust the value loaded at launch.
  void _checkDayChange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_lastCheckedDate == null || today != _lastCheckedDate) {
      _lastCheckedDate = today;
      ref.read(gameStreakNotifierProvider.notifier).refreshStatus();
    }
  }

  @override
  void dispose() {
    _dayCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(gameStreakNotifierProvider.notifier).refreshStatus();
    }
  }

  void _select(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
      _visited.add(index);
    });
  }

  Widget _tab(int index, Widget child) {
    return _visited.contains(index) ? child : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool wide = size.width > 600;
    // A short phone cannot spare 58dp of board for a tab bar; the deal goes
    // full height and keeps a way back in its own top bar.
    final bool short = size.height < 720;
    final List<Widget> tabs = [
      _tab(0, FeedScreen(onBrowse: short ? () => _select(1) : null)),
      _tab(1, const DiscoveryHomeScreen()),
      _tab(2, const StatsScreen()),
    ];

    return Scaffold(
      backgroundColor: DesignSystem.paperOf(context),
      body: wide
          ? Row(
              children: [
                _SideRail(
                  selectedIndex: _selectedIndex,
                  onSelect: _select,
                ),
                Expanded(
                  child: IndexedStack(index: _selectedIndex, children: tabs),
                ),
              ],
            )
          : IndexedStack(index: _selectedIndex, children: tabs),
      bottomNavigationBar: wide || (short && _selectedIndex == 0)
          ? null
          : _DeckBar(selectedIndex: _selectedIndex, onSelect: _select),
    );
  }
}

/// The three tabs, on a hairline. Labels are set in the display face because
/// they are two words long and always will be; the icons are the fallback for
/// the first week of use.
class _DeckBar extends StatelessWidget {
  const _DeckBar({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  /// Stable keys for the three tabs, so a test or a screenshot run can tap a
  /// room without guessing which 'Deal' label on screen it means.
  static const List<String> _roomKeys = ['deal', 'stack', 'you'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = <_Room>[
      _Room(null, l10n?.navDeal ?? 'Deal'),
      _Room(Icons.grid_view_rounded, l10n?.navStack ?? 'Stack'),
      _Room(Icons.person_outline_rounded, l10n?.navYou ?? 'You'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: DesignSystem.cardOf(context),
        border: Border(
          top: BorderSide(color: DesignSystem.hairline(context), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              for (int i = 0; i < entries.length; i++)
                Expanded(
                  child: _RoomButton(
                    key: ValueKey('tab_${_roomKeys[i]}'),
                    entry: entries[i],
                    selected: selectedIndex == i,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Room {
  const _Room(this.icon, this.label);

  /// Null for the deal, which carries the deck mark instead of an icon.
  final IconData? icon;
  final String label;
}

class _RoomButton extends StatelessWidget {
  const _RoomButton({
    super.key,
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final _Room entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color ink = Theme.of(context).colorScheme.onSurface;
    final Color muted = DesignSystem.muted(context);
    final Color accent = DesignSystem.accent(context);
    final Color color = selected ? accent : muted;

    return Semantics(
      button: true,
      selected: selected,
      label: entry.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (entry.icon == null)
              DeckMark(size: 20, color: color, liveColor: color)
            else
              Icon(entry.icon, size: 20, color: color),
            const SizedBox(height: 3),
            Text(
              entry.label.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Bebas Neue',
                fontSize: DesignSystem.fontSizeMD,
                letterSpacing: 1.2,
                height: 1,
                color: selected ? ink : muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The same three rooms on a tablet or desktop, where a bottom bar would sit a
/// metre away from the puzzle.
class _SideRail extends StatelessWidget {
  const _SideRail({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = <_Room>[
      _Room(null, l10n?.navDeal ?? 'Deal'),
      _Room(Icons.grid_view_rounded, l10n?.navStack ?? 'Stack'),
      _Room(Icons.person_outline_rounded, l10n?.navYou ?? 'You'),
    ];

    return Container(
      key: const ValueKey('side_rail'),
      width: 96,
      decoration: BoxDecoration(
        color: DesignSystem.cardOf(context),
        border: Border(
          right: BorderSide(color: DesignSystem.hairline(context), width: 1),
        ),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < entries.length; i++) ...[
              _RoomButton(
                entry: entries[i],
                selected: selectedIndex == i,
                onTap: () => onSelect(i),
              ),
              if (i != entries.length - 1) const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    );
  }
}

/// Settings, for the two places that need an entry point.
void openSettings(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const SettingsScreen()),
  );
}
