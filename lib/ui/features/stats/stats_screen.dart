import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/game_providers.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/ui/features/home/widgets/daily_progress_banner.dart';
import 'package:puzzle/utils/design_system.dart';
import 'package:puzzle/widgets/deck.dart';
import 'package:puzzle/ui/features/main_shell/main_shell.dart';

class Achievement {
  final String title;
  final String description;
  final int requiredXp;
  final IconData icon;

  Achievement({
    required this.title,
    required this.description,
    required this.requiredXp,
    required this.icon,
  });
}

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  static List<Achievement> getAchievements(AppLocalizations l10n) => [
        Achievement(
          title: l10n.achievementSeeker,
          description: l10n.achievementSeekerDesc,
          requiredXp: 100,
          icon: Icons.search_rounded,
        ),
        Achievement(
          title: l10n.achievementApprentice,
          description: l10n.achievementApprenticeDesc,
          requiredXp: 1000,
          icon: Icons.school_rounded,
        ),
        Achievement(
          title: l10n.achievementStrategist,
          description: l10n.achievementStrategistDesc,
          requiredXp: 5000,
          icon: Icons.psychology_rounded,
        ),
        Achievement(
          title: l10n.achievementElite,
          description: l10n.achievementEliteDesc,
          requiredXp: 10000,
          icon: Icons.military_tech_rounded,
        ),
        Achievement(
          title: l10n.achievementVeteran,
          description: l10n.achievementVeteranDesc,
          requiredXp: 25000,
          icon: Icons.shield_rounded,
        ),
        Achievement(
          title: l10n.achievementMaster,
          description: l10n.achievementMasterDesc,
          requiredXp: 50000,
          icon: Icons.workspace_premium_rounded,
        ),
        Achievement(
          title: l10n.achievementGrandmaster,
          description: l10n.achievementGrandmasterDesc,
          requiredXp: 100000,
          icon: Icons.diamond_rounded,
        ),
        Achievement(
          title: l10n.achievementLegend,
          description: l10n.achievementLegendDesc,
          requiredXp: 250000,
          icon: Icons.auto_awesome_rounded,
        ),
        Achievement(
          title: l10n.achievementMythic,
          description: l10n.achievementMythicDesc,
          requiredXp: 500000,
          icon: Icons.vignette_rounded,
        ),
        Achievement(
          title: l10n.achievementEternal,
          description: l10n.achievementEternalDesc,
          requiredXp: 1000000,
          icon: Icons.all_inclusive_rounded,
        ),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final achievements = StatsScreen.getAchievements(l10n);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  floating: false,
                  snap: false,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  centerTitle: true,
                  title: Text(
                    l10n.statsTitle,
                    style: theme.textTheme.displaySmall?.copyWith(
                      letterSpacing: 2.0,
                    ),
                  ),
                  actions: [
                    IconButton(
                      tooltip: l10n.settings,
                      onPressed: () => openSettings(context),
                      icon: Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: DesignSystem.muted(context),
                      ),
                    ),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignSystem.spaceLG,
                    DesignSystem.spaceMD,
                    DesignSystem.spaceLG,
                    140,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == 0) return _UserStatsCard(l10n: l10n);
                        if (index == 1)
                          return const SizedBox(height: DesignSystem.spaceXL);
                        if (index == 2)
                          return _CognitiveProfileCard(l10n: l10n);
                        if (index == 3)
                          return const SizedBox(height: DesignSystem.spaceXL);
                        if (index == 4) {
                          return Text(
                            l10n.statsAchievements,
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontSize: DesignSystem.fontSizeXL,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: 0.6,
                            ),
                          );
                        }
                        if (index == 5)
                          return const SizedBox(height: DesignSystem.spaceMD);
                        final achievementIndex = index - 6;
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: DesignSystem.spaceMD),
                          child: _AchievementCard(
                              achievement: achievements[achievementIndex],
                              l10n: l10n),
                        );
                      },
                      childCount: 6 + achievements.length,
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
}

class _UserStatsCard extends ConsumerWidget {
  final AppLocalizations l10n;
  const _UserStatsCard({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userData = ref.watch(userDataNotifierProvider);
    final notifier = ref.read(userDataNotifierProvider.notifier);

    final level = userData.level;
    final xp = userData.xp;
    final currentLevelXp = notifier.xpForLevel(level);
    final nextLevelXp = notifier.xpForLevel(level + 1);

    final diff = nextLevelXp - currentLevelXp;
    final progress = diff > 0 ? (xp - currentLevelXp) / diff : 1.0;

    return Column(
      children: [
        _StreakTracker(l10n: l10n),
        const SizedBox(height: DesignSystem.spaceMD),
        const DailyProgressBanner(),
        const SizedBox(height: DesignSystem.spaceMD),
        DeckCard(
          padding: const EdgeInsets.all(DesignSystem.spaceLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.statsLevel(level).toUpperCase(),
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 40,
                            height: 0.95,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.statsMaintainStreak,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: DesignSystem.muted(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.workspace_premium_rounded,
                    size: 26,
                    color: DesignSystem.muted(context),
                  ),
                ],
              ),
              const SizedBox(height: DesignSystem.spaceLG),
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignSystem.radiusFull),
                child: Stack(
                  children: [
                    Container(
                      height: 6,
                      width: double.infinity,
                      color: DesignSystem.hairline(context),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        height: 6,
                        color: DesignSystem.accent(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.statsPercentToLevel((progress * 100).toInt(), level + 1),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontFamily: 'Bebas Neue',
                  fontSize: DesignSystem.fontSizeSM,
                  color: DesignSystem.muted(context),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignSystem.spaceMD),
        Row(
          children: [
            Expanded(
              child: _SmallStatCard(
                label: l10n.statsTotalXp,
                value: '$xp',
                icon: Icons.bolt_rounded,
                color: DesignSystem.accentAmber,
              ),
            ),
            const SizedBox(width: DesignSystem.spaceMD),
            Expanded(
              child: _SmallStatCard(
                label: l10n.statsSolved,
                value: '${userData.totalSolved ?? 0}',
                icon: Icons.extension_rounded,
                color: DesignSystem.success,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StreakTracker extends ConsumerWidget {
  final AppLocalizations l10n;
  const _StreakTracker({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userData = ref.watch(userDataNotifierProvider);
    final superStreak = userData.superStreak ?? 0;
    final lastDate = userData.lastSuperStreakDate;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentWeekday = now.weekday;
    final mondayOfThisWeek = today.subtract(Duration(days: currentWeekday - 1));

    return DeckCard(
      padding: const EdgeInsets.all(DesignSystem.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.statsWeeklyActivity.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: DesignSystem.fontSizeXS,
                  fontWeight: FontWeight.w600,
                  color: DesignSystem.muted(context),
                  letterSpacing: 0.8,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.local_fire_department_rounded,
                      color: superStreak > 0
                          ? DesignSystem.accent(context)
                          : DesignSystem.hairline(context),
                      size: 18),
                  const SizedBox(width: 4),
                  Text(
                    l10n.statsDayStreak(superStreak).toUpperCase(),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontSize: DesignSystem.fontSizeMD,
                      color: superStreak > 0
                          ? DesignSystem.accent(context)
                          : DesignSystem.muted(context),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: DesignSystem.spaceMD),
          Row(
            children: List.generate(7, (index) {
              final dayDate = mondayOfThisWeek.add(Duration(days: index));
              final dayLabel = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index];
              final isToday = dayDate.isAtSameMomentAs(today);

              bool isSolved = false;
              if (lastDate != null && superStreak > 0) {
                final lastNormalized =
                    DateTime(lastDate.year, lastDate.month, lastDate.day);
                final streakStart =
                    lastNormalized.subtract(Duration(days: superStreak - 1));

                if ((dayDate.isAtSameMomentAs(streakStart) ||
                        dayDate.isAfter(streakStart)) &&
                    (dayDate.isAtSameMomentAs(lastNormalized) ||
                        dayDate.isBefore(lastNormalized))) {
                  isSolved = true;
                }
              }

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 6 ? 0 : 4.0),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSolved
                            ? DesignSystem.accent(context)
                            : DesignSystem.cardOf(context),
                        borderRadius:
                            BorderRadius.circular(DesignSystem.radiusSM),
                        border: Border.all(
                          color: isToday
                              ? DesignSystem.accent(context)
                              : DesignSystem.hairline(context),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: isSolved
                            ? Icon(Icons.check_rounded,
                                color: DesignSystem.onAccent(context), size: 18)
                            : Text(
                                dayLabel,
                                style: TextStyle(
                                  fontFamily: 'Geist',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: isToday
                                      ? DesignSystem.accent(context)
                                      : DesignSystem.muted(context),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CognitiveProfileCard extends ConsumerWidget {
  final AppLocalizations l10n;
  const _CognitiveProfileCard({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final totalStats = ref.watch(categoryStatsProvider);
    final solvedStatsMap = ref.watch(solvedStatsProvider);

    final categories = totalStats.keys.where((k) => k != 'ALL').toList()
      ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.statsCognitiveProfile.toUpperCase(),
          style: theme.textTheme.displaySmall?.copyWith(
            fontSize: DesignSystem.fontSizeXL,
            color: colorScheme.onSurface,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: DesignSystem.spaceMD),
        DeckCard(
          padding: const EdgeInsets.all(DesignSystem.spaceMD),
          child: Column(
            children: categories.map((cat) {
              final solved = solvedStatsMap[cat] ?? 0;
              final total = totalStats[cat] ?? 1;
              // One colour for every room: the bar is progress, not identity.
              final color = DesignSystem.accent(context);

              return Padding(
                padding: const EdgeInsets.only(bottom: DesignSystem.spaceMD),
                child: _CategoryProgressItem(
                  category: cat,
                  solved: solved,
                  total: total,
                  color: color,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _CategoryProgressItem extends StatelessWidget {
  final String category;
  final int solved;
  final int total;
  final Color color;

  const _CategoryProgressItem({
    required this.category,
    required this.solved,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = (solved / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category[0] + category.substring(1).toLowerCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: DesignSystem.fontSizeXS,
                color: colorScheme.onSurface,
                letterSpacing: 0.2,
              ),
            ),
            DeckNumber('$solved / $total',
                size: 16, color: DesignSystem.muted(context)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(DesignSystem.radiusFull),
          child: Stack(
            children: [
              Container(
                height: 4,
                width: double.infinity,
                color: DesignSystem.hairline(context),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(height: 4, color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SmallStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DeckCard(
      padding: const EdgeInsets.all(DesignSystem.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: DesignSystem.muted(context)),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: DesignSystem.muted(context),
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          DeckNumber(value, size: 34),
        ],
      ),
    );
  }
}

class _AchievementCard extends ConsumerWidget {
  final Achievement achievement;
  final AppLocalizations l10n;

  const _AchievementCard({required this.achievement, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xp = ref.watch(userDataNotifierProvider.select((d) => d.xp));
    final isUnlocked = xp >= achievement.requiredXp;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color accent = DesignSystem.accent(context);
    return DeckCard(
      padding: const EdgeInsets.all(DesignSystem.spaceMD),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isUnlocked ? accent : DesignSystem.hairline(context),
              ),
            ),
            child: Icon(
              achievement.icon,
              size: 22,
              color: isUnlocked ? accent : DesignSystem.muted(context),
            ),
          ),
          const SizedBox(width: DesignSystem.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title.toUpperCase(),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontSize: DesignSystem.fontSizeLG,
                    color: isUnlocked
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withValues(alpha: 0.35),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isUnlocked
                        ? colorScheme.onSurface.withValues(alpha: 0.6)
                        : colorScheme.onSurface.withValues(alpha: 0.2),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          if (isUnlocked)
            Icon(Icons.check_rounded, size: 20, color: accent)
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(DesignSystem.radiusXS),
              ),
              child: Text(
                l10n.statsLocked,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  letterSpacing: 1.5,
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
