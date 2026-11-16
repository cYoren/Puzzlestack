// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compass_maze_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CompassMazeNotifier)
final compassMazeProvider = CompassMazeNotifierProvider._();

final class CompassMazeNotifierProvider
    extends $NotifierProvider<CompassMazeNotifier, CompassMazeState> {
  CompassMazeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'compassMazeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$compassMazeNotifierHash();

  @$internal
  @override
  CompassMazeNotifier create() => CompassMazeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CompassMazeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CompassMazeState>(value),
    );
  }
}

String _$compassMazeNotifierHash() =>
    r'1317c9e6db85c8db75ca5a5aa95ac08075cca385';

abstract class _$CompassMazeNotifier extends $Notifier<CompassMazeState> {
  CompassMazeState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CompassMazeState, CompassMazeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CompassMazeState, CompassMazeState>,
              CompassMazeState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
