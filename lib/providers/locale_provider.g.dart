// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Persists the user-selected app locale (or `null` for system default).
///
/// Mirrors the Hive-backed pattern used by [ThemeNotifier].

@ProviderFor(LocaleNotifier)
final localeProvider = LocaleNotifierProvider._();

/// Persists the user-selected app locale (or `null` for system default).
///
/// Mirrors the Hive-backed pattern used by [ThemeNotifier].
final class LocaleNotifierProvider
    extends $NotifierProvider<LocaleNotifier, Locale?> {
  /// Persists the user-selected app locale (or `null` for system default).
  ///
  /// Mirrors the Hive-backed pattern used by [ThemeNotifier].
  LocaleNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localeNotifierHash();

  @$internal
  @override
  LocaleNotifier create() => LocaleNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Locale? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Locale?>(value),
    );
  }
}

String _$localeNotifierHash() => r'012810658db43e0fe9175e945fa5305ef9836c03';

/// Persists the user-selected app locale (or `null` for system default).
///
/// Mirrors the Hive-backed pattern used by [ThemeNotifier].

abstract class _$LocaleNotifier extends $Notifier<Locale?> {
  Locale? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Locale?, Locale?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Locale?, Locale?>,
              Locale?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
