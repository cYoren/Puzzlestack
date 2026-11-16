// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fraction_match_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FractionMatchNotifier)
final fractionMatchProvider = FractionMatchNotifierProvider._();

final class FractionMatchNotifierProvider
    extends $NotifierProvider<FractionMatchNotifier, FractionMatchState> {
  FractionMatchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fractionMatchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fractionMatchNotifierHash();

  @$internal
  @override
  FractionMatchNotifier create() => FractionMatchNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FractionMatchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FractionMatchState>(value),
    );
  }
}

String _$fractionMatchNotifierHash() =>
    r'b4f7ad5bcdd66517edf9cb9f933e577a687846b1';

abstract class _$FractionMatchNotifier extends $Notifier<FractionMatchState> {
  FractionMatchState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FractionMatchState, FractionMatchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FractionMatchState, FractionMatchState>,
              FractionMatchState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
