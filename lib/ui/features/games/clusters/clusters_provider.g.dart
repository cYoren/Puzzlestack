// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clusters_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ClustersNotifier)
final clustersProvider = ClustersNotifierProvider._();

final class ClustersNotifierProvider
    extends $NotifierProvider<ClustersNotifier, ClustersState> {
  ClustersNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clustersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clustersNotifierHash();

  @$internal
  @override
  ClustersNotifier create() => ClustersNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClustersState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClustersState>(value),
    );
  }
}

String _$clustersNotifierHash() => r'67d0265e23625cd8d7b3f412388c7a03c5f1839b';

abstract class _$ClustersNotifier extends $Notifier<ClustersState> {
  ClustersState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ClustersState, ClustersState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ClustersState, ClustersState>,
              ClustersState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
