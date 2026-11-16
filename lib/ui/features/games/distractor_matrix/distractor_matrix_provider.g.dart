// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'distractor_matrix_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DistractorMatrixNotifier)
final distractorMatrixProvider = DistractorMatrixNotifierProvider._();

final class DistractorMatrixNotifierProvider
    extends $NotifierProvider<DistractorMatrixNotifier, DistractorMatrixState> {
  DistractorMatrixNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'distractorMatrixProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$distractorMatrixNotifierHash();

  @$internal
  @override
  DistractorMatrixNotifier create() => DistractorMatrixNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DistractorMatrixState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DistractorMatrixState>(value),
    );
  }
}

String _$distractorMatrixNotifierHash() =>
    r'1f99810ff6365691ce2972466cf91b59dc94b46d';

abstract class _$DistractorMatrixNotifier
    extends $Notifier<DistractorMatrixState> {
  DistractorMatrixState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DistractorMatrixState, DistractorMatrixState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DistractorMatrixState, DistractorMatrixState>,
              DistractorMatrixState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
