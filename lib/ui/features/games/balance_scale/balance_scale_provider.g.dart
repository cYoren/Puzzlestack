// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance_scale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BalanceScaleNotifier)
final balanceScaleProvider = BalanceScaleNotifierProvider._();

final class BalanceScaleNotifierProvider
    extends $NotifierProvider<BalanceScaleNotifier, BalanceScaleState> {
  BalanceScaleNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'balanceScaleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$balanceScaleNotifierHash();

  @$internal
  @override
  BalanceScaleNotifier create() => BalanceScaleNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BalanceScaleState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BalanceScaleState>(value),
    );
  }
}

String _$balanceScaleNotifierHash() =>
    r'9859b3ff2c90b1150d6a22c0dcdf9ffc9b7caecd';

abstract class _$BalanceScaleNotifier extends $Notifier<BalanceScaleState> {
  BalanceScaleState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BalanceScaleState, BalanceScaleState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BalanceScaleState, BalanceScaleState>,
              BalanceScaleState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
