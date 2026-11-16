// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cube_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CubeNotifier)
final cubeProvider = CubeNotifierProvider._();

final class CubeNotifierProvider
    extends $NotifierProvider<CubeNotifier, CubeState> {
  CubeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cubeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cubeNotifierHash();

  @$internal
  @override
  CubeNotifier create() => CubeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CubeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CubeState>(value),
    );
  }
}

String _$cubeNotifierHash() => r'b03478e82df3de24ae76ae183e55fd2e0d098cf7';

abstract class _$CubeNotifier extends $Notifier<CubeState> {
  CubeState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CubeState, CubeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CubeState, CubeState>,
              CubeState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
