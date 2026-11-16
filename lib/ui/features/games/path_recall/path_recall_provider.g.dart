// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'path_recall_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PathRecallNotifier)
final pathRecallProvider = PathRecallNotifierProvider._();

final class PathRecallNotifierProvider
    extends $NotifierProvider<PathRecallNotifier, PathRecallState> {
  PathRecallNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pathRecallProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pathRecallNotifierHash();

  @$internal
  @override
  PathRecallNotifier create() => PathRecallNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PathRecallState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PathRecallState>(value),
    );
  }
}

String _$pathRecallNotifierHash() =>
    r'0bdc6efaf939bb8c620682776372fe42beaf9b72';

abstract class _$PathRecallNotifier extends $Notifier<PathRecallState> {
  PathRecallState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PathRecallState, PathRecallState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PathRecallState, PathRecallState>,
              PathRecallState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
