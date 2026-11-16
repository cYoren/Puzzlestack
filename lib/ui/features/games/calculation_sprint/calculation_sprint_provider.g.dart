// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calculation_sprint_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CalculationSprintNotifier)
final calculationSprintProvider = CalculationSprintNotifierProvider._();

final class CalculationSprintNotifierProvider
    extends
        $NotifierProvider<CalculationSprintNotifier, CalculationSprintState> {
  CalculationSprintNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calculationSprintProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calculationSprintNotifierHash();

  @$internal
  @override
  CalculationSprintNotifier create() => CalculationSprintNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalculationSprintState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalculationSprintState>(value),
    );
  }
}

String _$calculationSprintNotifierHash() =>
    r'b88c3ee99b7a46dfb030cf54531bf491df1604c8';

abstract class _$CalculationSprintNotifier
    extends $Notifier<CalculationSprintState> {
  CalculationSprintState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<CalculationSprintState, CalculationSprintState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CalculationSprintState, CalculationSprintState>,
              CalculationSprintState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
