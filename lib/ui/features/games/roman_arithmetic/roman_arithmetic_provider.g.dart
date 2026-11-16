// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'roman_arithmetic_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RomanArithmeticNotifier)
final romanArithmeticProvider = RomanArithmeticNotifierProvider._();

final class RomanArithmeticNotifierProvider
    extends $NotifierProvider<RomanArithmeticNotifier, RomanArithmeticState> {
  RomanArithmeticNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'romanArithmeticProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$romanArithmeticNotifierHash();

  @$internal
  @override
  RomanArithmeticNotifier create() => RomanArithmeticNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RomanArithmeticState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RomanArithmeticState>(value),
    );
  }
}

String _$romanArithmeticNotifierHash() =>
    r'70b1e0eee69a0085c1db8def857ba8a9d1e82ce0';

abstract class _$RomanArithmeticNotifier
    extends $Notifier<RomanArithmeticState> {
  RomanArithmeticState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RomanArithmeticState, RomanArithmeticState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RomanArithmeticState, RomanArithmeticState>,
              RomanArithmeticState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
