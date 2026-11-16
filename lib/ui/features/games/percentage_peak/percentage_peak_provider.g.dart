// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'percentage_peak_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PercentagePeakNotifier)
final percentagePeakProvider = PercentagePeakNotifierProvider._();

final class PercentagePeakNotifierProvider
    extends $NotifierProvider<PercentagePeakNotifier, PercentagePeakState> {
  PercentagePeakNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'percentagePeakProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$percentagePeakNotifierHash();

  @$internal
  @override
  PercentagePeakNotifier create() => PercentagePeakNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PercentagePeakState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PercentagePeakState>(value),
    );
  }
}

String _$percentagePeakNotifierHash() =>
    r'6df5c44065c473595c0f1bf6d0f2e63240bc9b29';

abstract class _$PercentagePeakNotifier extends $Notifier<PercentagePeakState> {
  PercentagePeakState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PercentagePeakState, PercentagePeakState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PercentagePeakState, PercentagePeakState>,
              PercentagePeakState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
