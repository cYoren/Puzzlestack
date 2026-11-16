// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'path_intersect_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PathIntersectNotifier)
final pathIntersectProvider = PathIntersectNotifierProvider._();

final class PathIntersectNotifierProvider
    extends $NotifierProvider<PathIntersectNotifier, PathIntersectState> {
  PathIntersectNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pathIntersectProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pathIntersectNotifierHash();

  @$internal
  @override
  PathIntersectNotifier create() => PathIntersectNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PathIntersectState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PathIntersectState>(value),
    );
  }
}

String _$pathIntersectNotifierHash() =>
    r'00ef2baf08586766f333c6ff931385726a2b8c76';

abstract class _$PathIntersectNotifier extends $Notifier<PathIntersectState> {
  PathIntersectState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PathIntersectState, PathIntersectState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PathIntersectState, PathIntersectState>,
              PathIntersectState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
