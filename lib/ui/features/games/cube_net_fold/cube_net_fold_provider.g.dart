// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cube_net_fold_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CubeNetFoldNotifier)
final cubeNetFoldProvider = CubeNetFoldNotifierProvider._();

final class CubeNetFoldNotifierProvider
    extends $NotifierProvider<CubeNetFoldNotifier, CubeNetFoldState> {
  CubeNetFoldNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cubeNetFoldProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cubeNetFoldNotifierHash();

  @$internal
  @override
  CubeNetFoldNotifier create() => CubeNetFoldNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CubeNetFoldState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CubeNetFoldState>(value),
    );
  }
}

String _$cubeNetFoldNotifierHash() =>
    r'f3f3e9bc220385ede76643e158aa479887ff22a3';

abstract class _$CubeNetFoldNotifier extends $Notifier<CubeNetFoldState> {
  CubeNetFoldState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CubeNetFoldState, CubeNetFoldState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CubeNetFoldState, CubeNetFoldState>,
              CubeNetFoldState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
