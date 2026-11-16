// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tower_of_london_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TowerOfLondonNotifier)
final towerOfLondonProvider = TowerOfLondonNotifierProvider._();

final class TowerOfLondonNotifierProvider
    extends $NotifierProvider<TowerOfLondonNotifier, TowerOfLondonState> {
  TowerOfLondonNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'towerOfLondonProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$towerOfLondonNotifierHash();

  @$internal
  @override
  TowerOfLondonNotifier create() => TowerOfLondonNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TowerOfLondonState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TowerOfLondonState>(value),
    );
  }
}

String _$towerOfLondonNotifierHash() =>
    r'8a8da60f5446f1daca8f0bce3103a37aa32b1382';

abstract class _$TowerOfLondonNotifier extends $Notifier<TowerOfLondonState> {
  TowerOfLondonState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TowerOfLondonState, TowerOfLondonState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TowerOfLondonState, TowerOfLondonState>,
              TowerOfLondonState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
