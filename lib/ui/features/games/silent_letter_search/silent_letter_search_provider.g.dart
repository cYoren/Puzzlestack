// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'silent_letter_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SilentLetterSearchNotifier)
final silentLetterSearchProvider = SilentLetterSearchNotifierProvider._();

final class SilentLetterSearchNotifierProvider
    extends
        $NotifierProvider<SilentLetterSearchNotifier, SilentLetterSearchState> {
  SilentLetterSearchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'silentLetterSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$silentLetterSearchNotifierHash();

  @$internal
  @override
  SilentLetterSearchNotifier create() => SilentLetterSearchNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SilentLetterSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SilentLetterSearchState>(value),
    );
  }
}

String _$silentLetterSearchNotifierHash() =>
    r'bd6d7f610f5d39767831a0d63ba221eb42c737a4';

abstract class _$SilentLetterSearchNotifier
    extends $Notifier<SilentLetterSearchState> {
  SilentLetterSearchState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<SilentLetterSearchState, SilentLetterSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SilentLetterSearchState, SilentLetterSearchState>,
              SilentLetterSearchState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
