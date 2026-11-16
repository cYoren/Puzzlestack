// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visual_statistical_learning_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VisualStatisticalLearningNotifier)
final visualStatisticalLearningProvider =
    VisualStatisticalLearningNotifierProvider._();

final class VisualStatisticalLearningNotifierProvider
    extends $NotifierProvider<VisualStatisticalLearningNotifier, VSLState> {
  VisualStatisticalLearningNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visualStatisticalLearningProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$visualStatisticalLearningNotifierHash();

  @$internal
  @override
  VisualStatisticalLearningNotifier create() =>
      VisualStatisticalLearningNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VSLState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VSLState>(value),
    );
  }
}

String _$visualStatisticalLearningNotifierHash() =>
    r'607731e7f4a162072f4e5eda28ef3616b195c052';

abstract class _$VisualStatisticalLearningNotifier extends $Notifier<VSLState> {
  VSLState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<VSLState, VSLState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VSLState, VSLState>,
              VSLState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
