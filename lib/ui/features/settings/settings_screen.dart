import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import '../../../providers/theme_provider.dart';

import '../../../providers/user_providers.dart';
import '../../../utils/design_system.dart';
import '../../../widgets/deck.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeMode = ref.watch(themeNotifierProvider);
    final isTrialModeEnabled = ref.watch(
        userDataNotifierProvider.select((s) => s.isTrialModeEnabled ?? false));
    final l10n = AppLocalizations.of(context)!;

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
                  surfaceTintColor: Colors.transparent,
                  centerTitle: true,
                  title: Text(
                    l10n.settings.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Bebas Neue',
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      fontSize: DesignSystem
                          .fontSize2XL, // Beautiful large Bebas Neue title
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignSystem.spaceLG,
                    DesignSystem.spaceMD,
                    DesignSystem.spaceLG,
                    DesignSystem.space3XL,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSectionTitle(context, l10n.appearance),
                      const SizedBox(height: DesignSystem.spaceSM),
                      _buildThemeSelector(context, ref, themeMode, l10n),
                      const SizedBox(height: DesignSystem.spaceXL),
                      _buildSectionTitle(context, l10n.gameplay),
                      const SizedBox(height: DesignSystem.spaceSM),
                      _buildTrialModeToggle(
                          context, ref, isTrialModeEnabled, l10n),
                      const SizedBox(height: DesignSystem.spaceXL),
                      _buildSectionTitle(context, l10n.supportUs),
                      const SizedBox(height: DesignSystem.spaceSM),
                      _buildGroup(context, [
                        _buildRow(
                          context,
                          l10n.starOnGithub,
                          Icons.star_outline_rounded,
                          () => _launchUrl(
                              'https://github.com/cYoren/Puzzlestack'),
                        ),
                        _buildRow(
                          context,
                          l10n.leaveReview,
                          Icons.rate_review_outlined,
                          () => _launchUrl(
                              'https://play.google.com/store/apps/details?id=com.medhub.puzzlestack'),
                        ),
                        _buildRow(
                          context,
                          l10n.reportError,
                          Icons.bug_report_outlined,
                          () => _launchUrl(
                              'https://github.com/cYoren/Puzzlestack/issues'),
                        ),
                      ]),
                      const SizedBox(height: DesignSystem.spaceXL),
                      _buildSectionTitle(context, l10n.systemLegal),
                      const SizedBox(height: DesignSystem.spaceSM),
                      _buildGroup(context, [
                        _buildRow(
                          context,
                          l10n.privacyPolicy,
                          Icons.privacy_tip_outlined,
                          () => _launchUrl(
                              'https://cyoren.github.io/Puzzlestack/privacy.html'),
                        ),
                        _buildRow(
                          context,
                          l10n.termsOfService,
                          Icons.description_outlined,
                          () => _launchUrl(
                              'https://cyoren.github.io/Puzzlestack/terms.html'),
                        ),
                        _buildRow(
                          context,
                          l10n.licenses,
                          Icons.code_rounded,
                          () => showLicensePage(
                            context: context,
                            applicationName: l10n.appTitle.toUpperCase(),
                            applicationVersion: 'Latest',
                          ),
                        ),
                      ]),
                      const SizedBox(height: DesignSystem.spaceXL),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontFamily: 'Bebas Neue',
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: 0.6,
        fontWeight: FontWeight.w700,
        fontSize: DesignSystem.fontSizeXL,
      ),
    );
  }

  /// One card per group, rows divided by a hairline. A settings page is a list,
  /// and a list belongs in one card rather than five floating ones.
  Widget _buildGroup(BuildContext context, List<Widget> rows) {
    final List<Widget> spaced = [];
    for (int i = 0; i < rows.length; i++) {
      spaced.add(rows[i]);
      if (i != rows.length - 1) {
        spaced.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: 52,
            color: DesignSystem.hairline(context),
          ),
        );
      }
    }
    return DeckCard(padding: EdgeInsets.zero, child: Column(children: spaced));
  }

  Widget _buildRow(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 20, color: DesignSystem.muted(context)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: DesignSystem.fontSizeMD,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: DesignSystem.hairline(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrialModeToggle(BuildContext context, WidgetRef ref,
      bool isEnabled, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color accent = DesignSystem.accent(context);
    return DeckCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          Icon(
            Icons.timer_off_outlined,
            size: 20,
            color: isEnabled ? accent : DesignSystem.muted(context),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.trialMode,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: DesignSystem.fontSizeMD,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.trialModeDescription,
                  style: TextStyle(
                    fontSize: DesignSystem.fontSizeXS,
                    height: 1.3,
                    color: DesignSystem.muted(context),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (value) =>
                ref.read(userDataNotifierProvider.notifier).setTrialMode(value),
            activeThumbColor: accent,
            activeTrackColor: accent.withValues(alpha: 0.35),
            inactiveThumbColor: DesignSystem.cardOf(context),
            inactiveTrackColor: DesignSystem.hairline(context),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, WidgetRef ref,
      AppThemeMode currentMode, AppLocalizations l10n) {
    return _buildGroup(context, [
      _buildThemeOption(context, ref, AppThemeMode.light, l10n.themeLight,
          Icons.light_mode_outlined, currentMode == AppThemeMode.light),
      _buildThemeOption(context, ref, AppThemeMode.dark, l10n.themeDark,
          Icons.dark_mode_outlined, currentMode == AppThemeMode.dark),
      _buildThemeOption(context, ref, AppThemeMode.system, l10n.themeSystem,
          Icons.brightness_auto_outlined, currentMode == AppThemeMode.system),
    ]);
  }

  Widget _buildThemeOption(BuildContext context, WidgetRef ref,
      AppThemeMode mode, String label, IconData icon, bool isSelected) {
    final Color accent = DesignSystem.accent(context);
    return InkWell(
      onTap: () => ref.read(themeNotifierProvider.notifier).setThemeMode(mode),
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? accent : DesignSystem.muted(context),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: DesignSystem.fontSizeMD,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_rounded, size: 18, color: accent)
              else
                const SizedBox(width: 18),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }
}
