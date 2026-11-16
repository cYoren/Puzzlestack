// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fibonacci_merge_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FibonacciMergeNotifier)
final fibonacciMergeProvider = FibonacciMergeNotifierProvider._();

final class FibonacciMergeNotifierProvider
    extends $NotifierProvider<FibonacciMergeNotifier, FibonacciMergeState> {
  FibonacciMergeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fibonacciMergeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fibonacciMergeNotifierHash();

  @$internal
  @override
  FibonacciMergeNotifier create() => FibonacciMergeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FibonacciMergeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FibonacciMergeState>(value),
    );
  }
}

String _$fibonacciMergeNotifierHash() =>
    r'985d50245b9cc1cf6898db3daf630510bfbf79d1';

abstract class _$FibonacciMergeNotifier extends $Notifier<FibonacciMergeState> {
  FibonacciMergeState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FibonacciMergeState, FibonacciMergeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FibonacciMergeState, FibonacciMergeState>,
              FibonacciMergeState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
