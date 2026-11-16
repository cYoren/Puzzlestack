// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'factor_finder_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FactorFinderNotifier)
final factorFinderProvider = FactorFinderNotifierProvider._();

final class FactorFinderNotifierProvider
    extends $NotifierProvider<FactorFinderNotifier, FactorFinderState> {
  FactorFinderNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'factorFinderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$factorFinderNotifierHash();

  @$internal
  @override
  FactorFinderNotifier create() => FactorFinderNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FactorFinderState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FactorFinderState>(value),
    );
  }
}

String _$factorFinderNotifierHash() =>
    r'06a8b58cad6097748a420f5ccf236317a8e9d411';

abstract class _$FactorFinderNotifier extends $Notifier<FactorFinderState> {
  FactorFinderState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FactorFinderState, FactorFinderState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FactorFinderState, FactorFinderState>,
              FactorFinderState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
