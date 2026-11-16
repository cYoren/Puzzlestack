// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prime_hunter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PrimeHunterNotifier)
final primeHunterProvider = PrimeHunterNotifierProvider._();

final class PrimeHunterNotifierProvider
    extends $NotifierProvider<PrimeHunterNotifier, PrimeHunterState> {
  PrimeHunterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'primeHunterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$primeHunterNotifierHash();

  @$internal
  @override
  PrimeHunterNotifier create() => PrimeHunterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PrimeHunterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PrimeHunterState>(value),
    );
  }
}

String _$primeHunterNotifierHash() =>
    r'9426d700210d80a3f8c34391bbdacd4b760f69b4';

abstract class _$PrimeHunterNotifier extends $Notifier<PrimeHunterState> {
  PrimeHunterState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PrimeHunterState, PrimeHunterState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PrimeHunterState, PrimeHunterState>,
              PrimeHunterState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
