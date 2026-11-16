// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'arithmetic_chain_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ArithmeticChainNotifier)
final arithmeticChainProvider = ArithmeticChainNotifierProvider._();

final class ArithmeticChainNotifierProvider
    extends $NotifierProvider<ArithmeticChainNotifier, ArithmeticChainState> {
  ArithmeticChainNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'arithmeticChainProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$arithmeticChainNotifierHash();

  @$internal
  @override
  ArithmeticChainNotifier create() => ArithmeticChainNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ArithmeticChainState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ArithmeticChainState>(value),
    );
  }
}

String _$arithmeticChainNotifierHash() =>
    r'788cd0e796b9f23529e66c6146262933845eeda5';

abstract class _$ArithmeticChainNotifier
    extends $Notifier<ArithmeticChainState> {
  ArithmeticChainState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ArithmeticChainState, ArithmeticChainState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ArithmeticChainState, ArithmeticChainState>,
              ArithmeticChainState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
