// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'path_finder_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PathFinderNotifier)
final pathFinderProvider = PathFinderNotifierProvider._();

final class PathFinderNotifierProvider
    extends $NotifierProvider<PathFinderNotifier, PathFinderState> {
  PathFinderNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pathFinderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pathFinderNotifierHash();

  @$internal
  @override
  PathFinderNotifier create() => PathFinderNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PathFinderState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PathFinderState>(value),
    );
  }
}

String _$pathFinderNotifierHash() =>
    r'fc7f2430bc9cc2dd31c93a26d211be371e4d03b4';

abstract class _$PathFinderNotifier extends $Notifier<PathFinderState> {
  PathFinderState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PathFinderState, PathFinderState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PathFinderState, PathFinderState>,
              PathFinderState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
