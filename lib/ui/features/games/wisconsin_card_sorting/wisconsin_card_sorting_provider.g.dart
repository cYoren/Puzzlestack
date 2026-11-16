// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wisconsin_card_sorting_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WisconsinCardSortingNotifier)
final wisconsinCardSortingProvider = WisconsinCardSortingNotifierProvider._();

final class WisconsinCardSortingNotifierProvider
    extends $NotifierProvider<WisconsinCardSortingNotifier, WCSState> {
  WisconsinCardSortingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wisconsinCardSortingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wisconsinCardSortingNotifierHash();

  @$internal
  @override
  WisconsinCardSortingNotifier create() => WisconsinCardSortingNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WCSState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WCSState>(value),
    );
  }
}

String _$wisconsinCardSortingNotifierHash() =>
    r'0f2ac6d6fe8fadf053c2aa2089460c9325428d88';

abstract class _$WisconsinCardSortingNotifier extends $Notifier<WCSState> {
  WCSState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<WCSState, WCSState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WCSState, WCSState>,
              WCSState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
