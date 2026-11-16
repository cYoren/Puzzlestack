// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rotating_maze_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RotatingMazeNotifier)
final rotatingMazeProvider = RotatingMazeNotifierProvider._();

final class RotatingMazeNotifierProvider
    extends $NotifierProvider<RotatingMazeNotifier, RotatingMazeState> {
  RotatingMazeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rotatingMazeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rotatingMazeNotifierHash();

  @$internal
  @override
  RotatingMazeNotifier create() => RotatingMazeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RotatingMazeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RotatingMazeState>(value),
    );
  }
}

String _$rotatingMazeNotifierHash() =>
    r'dd3de5579b902211d7a77791634b35e9f6ac1258';

abstract class _$RotatingMazeNotifier extends $Notifier<RotatingMazeState> {
  RotatingMazeState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RotatingMazeState, RotatingMazeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RotatingMazeState, RotatingMazeState>,
              RotatingMazeState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
