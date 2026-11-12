import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/theme_provider.dart';

import '../../../providers/user_providers.dart';
import '../../../utils/design_system.dart';
import '../../../utils/l10n_game_helpers.dart';
import '../../../widgets/tangible.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // Native names for each supported language code, used as picker labels. Kept
  // language-stable (always rendered in native script) so the picker does not
  // mutate mid-use when the app language changes.
  static const Map<String, String> _nativeNames = {
    'ar': 'العربية',
    'bn': 'বাংলা',
    'de': 'Deutsch',
    'en': 'English',
    'es': 'Español',
    'fa': 'فارسی',
    'fr': 'Français',
    'hi': 'हिन्दी',
    'id': 'Bahasa Indonesia',
    'it': 'Italiano',
    'ja': '日本語',
    'ko': '한국어',
    'mr': 'मराठी',
    'pl': 'Polski',
    'pt': 'Português',
    'ru': 'Русский',
    'ta': 'தமிழ்',
    'te': 'తెలుగు',
    'th': 'ไทย',
    'tr': 'Türkçe',
    'ur': 'اردو',
    'vi': 'Tiếng Việt',
    'zh': '中文',
  };

  // Sentinel for the System Default entry. PopupMenuButton routes `null`
  // returns through onCanceled, so "system" is encoded as a non-null value and
  // translated back to `null` in the notifier.
  static const String _kSystemLocale = '__system__';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeMode = ref.watch(themeNotifierProvider);
    final isTrialModeEnabled = ref.watch(
        userDataNotifierProvider.select((s) => s.isTrialModeEnabled ?? false));
    final keepAwake = ref.watch(userDataNotifierProvider
        .select((s) => s.isKeepScreenAwakeEnabled ?? false));
    final hiddenIds = ref.watch(
        userDataNotifierProvider.select((s) => s.hiddenGameIds ?? const []));
    final currentLocale = ref.watch(localeNotifierProvider);
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
                    140, // Space for bottom nav
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSectionTitle(
                          context, l10n.appearance.toUpperCase()),
                      const SizedBox(height: DesignSystem.spaceMD),
                      _buildThemeSelector(context, ref, themeMode, l10n),
                      const SizedBox(height: DesignSystem.spaceSM),
                      _buildLanguageSelector(context, ref, currentLocale),
                      const SizedBox(height: DesignSystem.spaceXL),
                      _buildSectionTitle(context, l10n.gameplay.toUpperCase()),
                      const SizedBox(height: DesignSystem.spaceMD),
                      _buildTrialModeToggle(
                          context, ref, isTrialModeEnabled, l10n),
                      const SizedBox(height: DesignSystem.spaceSM),
                      _buildKeepAwakeToggle(context, ref, keepAwake, l10n),
                      if (hiddenIds.isNotEmpty) ...[
                        const SizedBox(height: DesignSystem.spaceSM),
                        _buildHiddenGamesRow(context, ref, hiddenIds, l10n),
                      ],
                      const SizedBox(height: DesignSystem.spaceXL),
                      _buildSectionTitle(context, l10n.supportUs.toUpperCase()),
                      const SizedBox(height: DesignSystem.spaceMD),
                      _buildSettingsItem(
                        context,
                        l10n.starOnGithub,
                        Icons.star_rounded,
                        () =>
                            _launchUrl('https://github.com/cYoren/Puzzlestack'),
                        iconColor: Colors.amber,
                      ),
                      const SizedBox(height: DesignSystem.spaceSM),
                      _buildSettingsItem(
                        context,
                        l10n.leaveReview,
                        Icons.rate_review_rounded,
                        () => _launchUrl(
                            'https://play.google.com/store/apps/details?id=com.medhub.puzzlestack'),
                        iconColor: Colors.teal,
                      ),
                      const SizedBox(height: DesignSystem.spaceSM),
                      _buildSettingsItem(
                        context,
                        l10n.reportError,
                        Icons.bug_report_rounded,
                        () => _launchUrl(
                            'https://github.com/cYoren/Puzzlestack/issues'),
                        iconColor: Colors.redAccent,
                      ),
                      const SizedBox(height: DesignSystem.spaceXL),
                      _buildSectionTitle(
                          context, l10n.systemLegal.toUpperCase()),
                      const SizedBox(height: DesignSystem.spaceMD),
                      _buildSettingsItem(
                        context,
                        l10n.privacyPolicy,
                        Icons.privacy_tip_rounded,
                        () => _launchUrl(
                            'https://cyoren.github.io/Puzzlestack/privacy.html'),
                      ),
                      const SizedBox(height: DesignSystem.spaceSM),
                      _buildSettingsItem(
                        context,
                        l10n.termsOfService,
                        Icons.description_rounded,
                        () => _launchUrl(
                            'https://cyoren.github.io/Puzzlestack/terms.html'),
                      ),
                      const SizedBox(height: DesignSystem.spaceSM),
                      _buildSettingsItem(
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
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Bebas Neue',
        color: colorScheme.primary,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
        fontSize:
            DesignSystem.fontSizeLG, // 18.0 is perfectly readable in Bebas Neue
      ),
    );
  }

  Widget _buildTrialModeToggle(BuildContext context, WidgetRef ref,
      bool isEnabled, AppLocalizations l10n) {
    return _buildSwitchCard(
      context,
      icon: Icons.timer_off_rounded,
      title: l10n.trialMode.toUpperCase(),
      subtitle: l10n.trialModeDescription.toUpperCase(),
      value: isEnabled,
      onChanged: (value) =>
          ref.read(userDataNotifierProvider.notifier).setTrialMode(value),
    );
  }

  Widget _buildKeepAwakeToggle(BuildContext context, WidgetRef ref,
      bool isEnabled, AppLocalizations l10n) {
    return _buildSwitchCard(
      context,
      icon: Icons.brightness_high_rounded,
      title: l10n.keepScreenAwake.toUpperCase(),
      subtitle: l10n.keepScreenAwakeDescription.toUpperCase(),
      value: isEnabled,
      onChanged: (value) =>
          ref.read(userDataNotifierProvider.notifier).setKeepScreenAwake(value),
    );
  }

  /// Hidden games can be restored only from here: the tile that hid a game is
  /// gone from every browse surface, so without this row hiding would be a
  /// one-way door.
  Widget _buildHiddenGamesRow(BuildContext context, WidgetRef ref,
      List<String> hiddenIds, AppLocalizations l10n) {
    return _buildSettingsItem(
      context,
      '${l10n.hiddenGames} (${hiddenIds.length})',
      Icons.visibility_off_rounded,
      () => _showHiddenGamesDialog(context, ref, hiddenIds),
    );
  }

  Future<void> _showHiddenGamesDialog(
      BuildContext context, WidgetRef ref, List<String> hiddenIds) async {
    final colorScheme = Theme.of(context).colorScheme;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: const Text(
          'HIDDEN GAMES',
          style: TextStyle(fontFamily: 'Bebas Neue', letterSpacing: 1.0),
        ),
        content: SizedBox(
          width: 320,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: hiddenIds.length,
            itemBuilder: (context, i) {
              final id = hiddenIds[i];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  L10nGameHelpers.getGameTitle(context, id),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.restore_rounded, size: 20),
                  onPressed: () => ref
                      .read(userDataNotifierProvider.notifier)
                      .toggleHideGame(id),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TangibleContainer(
      color: colorScheme.surface,
      shadowColor: colorScheme.outline.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(
          horizontal: DesignSystem.spaceMD, vertical: DesignSystem.spaceSM),
      child: Row(
        children: [
          Icon(
            icon,
            color: value
                ? DesignSystem.primary
                : colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: DesignSystem.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: DesignSystem.fontSizeMD,
                    letterSpacing: 0.5,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: DesignSystem.fontSize2XS,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: DesignSystem.primary,
          ),
        ],
      ),
    );
  }

  /// Language row. The app ships 23 locales; without this the player is locked
  /// to the device language, which is the wrong call for a bilingual phone.
  Widget _buildLanguageSelector(
      BuildContext context, WidgetRef ref, Locale? currentLocale) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final supportedCodes =
        AppLocalizations.supportedLocales.map((l) => l.languageCode).toList();
    final currentCode = currentLocale?.languageCode;
    final currentLabel = currentLocale == null
        ? 'System Default'
        : (_nativeNames[currentLocale.languageCode] ??
            currentLocale.languageCode.toUpperCase());

    return PopupMenuButton<String>(
      tooltip: '',
      position: PopupMenuPosition.under,
      onSelected: (code) {
        ref
            .read(localeNotifierProvider.notifier)
            .setLocale(code == _kSystemLocale ? null : Locale(code));
      },
      itemBuilder: (context) {
        final isSystem = currentLocale == null;
        return [
          _buildLanguageMenuItem(
            context,
            value: _kSystemLocale,
            label: 'System Default',
            selected: isSystem,
          ),
          const PopupMenuDivider(),
          for (final code in supportedCodes)
            _buildLanguageMenuItem(
              context,
              value: code,
              label: _nativeNames[code] ?? code.toUpperCase(),
              selected: code == currentCode,
            ),
        ];
      },
      child: TangibleButton(
        color: colorScheme.surface,
        onTap: null,
        child: Row(
          children: [
            Icon(
              Icons.translate_rounded,
              size: 24,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: DesignSystem.spaceMD),
            Expanded(
              child: Text(
                currentLabel.toUpperCase(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: DesignSystem.fontSizeMD,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Icon(
              Icons.expand_more_rounded,
              size: 24,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildLanguageMenuItem(
    BuildContext context, {
    required String value,
    required String label,
    required bool selected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.check_circle_rounded
                : Icons.radio_button_off_rounded,
            size: 18,
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(width: DesignSystem.spaceSM),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, WidgetRef ref,
      AppThemeMode currentMode, AppLocalizations l10n) {
    return Column(
      children: [
        _buildThemeOption(context, ref, AppThemeMode.light, l10n.themeLight,
            Icons.light_mode_rounded, currentMode == AppThemeMode.light),
        const SizedBox(height: DesignSystem.spaceSM),
        _buildThemeOption(context, ref, AppThemeMode.dark, l10n.themeDark,
            Icons.dark_mode_rounded, currentMode == AppThemeMode.dark),
        const SizedBox(height: DesignSystem.spaceSM),
        _buildThemeOption(context, ref, AppThemeMode.system, l10n.themeSystem,
            Icons.brightness_auto_rounded, currentMode == AppThemeMode.system),
      ],
    );
  }

  Widget _buildThemeOption(BuildContext context, WidgetRef ref,
      AppThemeMode mode, String label, IconData icon, bool isSelected) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color resolvedColor =
        isSelected ? colorScheme.primary : colorScheme.surface;
    final Color textColor = isSelected ? Colors.white : colorScheme.onSurface;
    final Color iconColor = isSelected
        ? Colors.white
        : colorScheme.onSurface.withValues(alpha: 0.7);

    return TangibleButton(
      color: resolvedColor,
      onTap: () => ref.read(themeNotifierProvider.notifier).setThemeMode(mode),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: iconColor,
          ),
          const SizedBox(width: DesignSystem.spaceMD),
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Geist',
                color: textColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: DesignSystem.fontSizeMD, // 16.0
                letterSpacing: 0.5,
              ),
            ),
          ),
          Icon(
            isSelected
                ? Icons.check_circle_rounded
                : Icons.radio_button_off_rounded,
            size: 24,
            color: isSelected
                ? Colors.white
                : colorScheme.onSurface.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    Color? iconColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TangibleButton(
      color: colorScheme.surface,
      shadowColor: colorScheme.outline.withValues(alpha: 0.5),
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: iconColor ?? colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: DesignSystem.spaceMD),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: DesignSystem.fontSizeMD, // Reduced from 14 to 13
                letterSpacing: 0.5,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 24,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ],
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
