// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matrix_reasoning_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MatrixReasoningNotifier)
final matrixReasoningProvider = MatrixReasoningNotifierProvider._();

final class MatrixReasoningNotifierProvider
    extends $NotifierProvider<MatrixReasoningNotifier, MatrixReasoningState> {
  MatrixReasoningNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'matrixReasoningProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$matrixReasoningNotifierHash();

  @$internal
  @override
  MatrixReasoningNotifier create() => MatrixReasoningNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MatrixReasoningState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MatrixReasoningState>(value),
    );
  }
}

String _$matrixReasoningNotifierHash() =>
    r'467d0c80254a9bd469937ed1acd055fa607d6856';

abstract class _$MatrixReasoningNotifier
    extends $Notifier<MatrixReasoningState> {
  MatrixReasoningState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MatrixReasoningState, MatrixReasoningState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MatrixReasoningState, MatrixReasoningState>,
              MatrixReasoningState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
