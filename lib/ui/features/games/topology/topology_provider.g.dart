// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topology_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TopologyNotifier)
final topologyProvider = TopologyNotifierProvider._();

final class TopologyNotifierProvider
    extends $NotifierProvider<TopologyNotifier, TopologyState> {
  TopologyNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'topologyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$topologyNotifierHash();

  @$internal
  @override
  TopologyNotifier create() => TopologyNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TopologyState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TopologyState>(value),
    );
  }
}

String _$topologyNotifierHash() => r'c102976b7a95df9606106e479970247c85d87cd8';

abstract class _$TopologyNotifier extends $Notifier<TopologyState> {
  TopologyState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TopologyState, TopologyState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TopologyState, TopologyState>,
              TopologyState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
