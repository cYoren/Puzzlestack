// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spoonerism_solver_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SpoonerismSolverNotifier)
final spoonerismSolverProvider = SpoonerismSolverNotifierProvider._();

final class SpoonerismSolverNotifierProvider
    extends $NotifierProvider<SpoonerismSolverNotifier, SpoonerismSolverState> {
  SpoonerismSolverNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'spoonerismSolverProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$spoonerismSolverNotifierHash();

  @$internal
  @override
  SpoonerismSolverNotifier create() => SpoonerismSolverNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpoonerismSolverState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SpoonerismSolverState>(value),
    );
  }
}

String _$spoonerismSolverNotifierHash() =>
    r'c70b410d9a9b21e4dd8cf4619bce2cdbd54dd0f3';

abstract class _$SpoonerismSolverNotifier
    extends $Notifier<SpoonerismSolverState> {
  SpoonerismSolverState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SpoonerismSolverState, SpoonerismSolverState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SpoonerismSolverState, SpoonerismSolverState>,
              SpoonerismSolverState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
