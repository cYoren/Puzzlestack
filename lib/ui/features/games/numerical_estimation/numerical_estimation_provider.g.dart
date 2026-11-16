// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'numerical_estimation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NumericalEstimationNotifier)
final numericalEstimationProvider = NumericalEstimationNotifierProvider._();

final class NumericalEstimationNotifierProvider
    extends
        $NotifierProvider<
          NumericalEstimationNotifier,
          NumericalEstimationState
        > {
  NumericalEstimationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'numericalEstimationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$numericalEstimationNotifierHash();

  @$internal
  @override
  NumericalEstimationNotifier create() => NumericalEstimationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NumericalEstimationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NumericalEstimationState>(value),
    );
  }
}

String _$numericalEstimationNotifierHash() =>
    r'41773cca15470787a007c6da5453ab10cd1450a0';

abstract class _$NumericalEstimationNotifier
    extends $Notifier<NumericalEstimationState> {
  NumericalEstimationState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<NumericalEstimationState, NumericalEstimationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NumericalEstimationState, NumericalEstimationState>,
              NumericalEstimationState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
