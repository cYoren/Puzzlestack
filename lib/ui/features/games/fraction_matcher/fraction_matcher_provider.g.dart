// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fraction_matcher_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FractionMatcherNotifier)
final fractionMatcherProvider = FractionMatcherNotifierProvider._();

final class FractionMatcherNotifierProvider
    extends $NotifierProvider<FractionMatcherNotifier, FractionMatcherState> {
  FractionMatcherNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fractionMatcherProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fractionMatcherNotifierHash();

  @$internal
  @override
  FractionMatcherNotifier create() => FractionMatcherNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FractionMatcherState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FractionMatcherState>(value),
    );
  }
}

String _$fractionMatcherNotifierHash() =>
    r'aa053a93632132893622f304fe8446495968703e';

abstract class _$FractionMatcherNotifier
    extends $Notifier<FractionMatcherState> {
  FractionMatcherState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FractionMatcherState, FractionMatcherState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FractionMatcherState, FractionMatcherState>,
              FractionMatcherState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
