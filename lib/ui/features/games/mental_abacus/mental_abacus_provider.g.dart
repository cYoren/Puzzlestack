// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mental_abacus_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MentalAbacusNotifier)
final mentalAbacusProvider = MentalAbacusNotifierProvider._();

final class MentalAbacusNotifierProvider
    extends $NotifierProvider<MentalAbacusNotifier, MentalAbacusState> {
  MentalAbacusNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mentalAbacusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mentalAbacusNotifierHash();

  @$internal
  @override
  MentalAbacusNotifier create() => MentalAbacusNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MentalAbacusState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MentalAbacusState>(value),
    );
  }
}

String _$mentalAbacusNotifierHash() =>
    r'2e19e98bf0962f54c3eb89997b0a2fd76c5f8726';

abstract class _$MentalAbacusNotifier extends $Notifier<MentalAbacusState> {
  MentalAbacusState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MentalAbacusState, MentalAbacusState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MentalAbacusState, MentalAbacusState>,
              MentalAbacusState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
