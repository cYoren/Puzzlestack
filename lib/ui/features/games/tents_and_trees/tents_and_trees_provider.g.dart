// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tents_and_trees_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TentsAndTreesNotifier)
final tentsAndTreesProvider = TentsAndTreesNotifierProvider._();

final class TentsAndTreesNotifierProvider
    extends $NotifierProvider<TentsAndTreesNotifier, TentsState> {
  TentsAndTreesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tentsAndTreesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tentsAndTreesNotifierHash();

  @$internal
  @override
  TentsAndTreesNotifier create() => TentsAndTreesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TentsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TentsState>(value),
    );
  }
}

String _$tentsAndTreesNotifierHash() =>
    r'357d921f24ed7d7ab0465522e047371ca7100197';

abstract class _$TentsAndTreesNotifier extends $Notifier<TentsState> {
  TentsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TentsState, TentsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TentsState, TentsState>,
              TentsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
