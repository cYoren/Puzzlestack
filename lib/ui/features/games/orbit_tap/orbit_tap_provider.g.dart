// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orbit_tap_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OrbitTapNotifier)
final orbitTapProvider = OrbitTapNotifierProvider._();

final class OrbitTapNotifierProvider
    extends $NotifierProvider<OrbitTapNotifier, OrbitTapState> {
  OrbitTapNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'orbitTapProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$orbitTapNotifierHash();

  @$internal
  @override
  OrbitTapNotifier create() => OrbitTapNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OrbitTapState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OrbitTapState>(value),
    );
  }
}

String _$orbitTapNotifierHash() => r'562e76f88881dc3f0933b3281155da4ad52b8d6d';

abstract class _$OrbitTapNotifier extends $Notifier<OrbitTapState> {
  OrbitTapState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<OrbitTapState, OrbitTapState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OrbitTapState, OrbitTapState>,
              OrbitTapState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
