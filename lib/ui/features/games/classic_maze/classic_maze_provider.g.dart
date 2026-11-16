// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classic_maze_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ClassicMazeNotifier)
final classicMazeProvider = ClassicMazeNotifierProvider._();

final class ClassicMazeNotifierProvider
    extends $NotifierProvider<ClassicMazeNotifier, ClassicMazeState> {
  ClassicMazeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'classicMazeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$classicMazeNotifierHash();

  @$internal
  @override
  ClassicMazeNotifier create() => ClassicMazeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClassicMazeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClassicMazeState>(value),
    );
  }
}

String _$classicMazeNotifierHash() =>
    r'9f69c03c427bfa2dc52887204d4775243bd992ac';

abstract class _$ClassicMazeNotifier extends $Notifier<ClassicMazeState> {
  ClassicMazeState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ClassicMazeState, ClassicMazeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ClassicMazeState, ClassicMazeState>,
              ClassicMazeState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
