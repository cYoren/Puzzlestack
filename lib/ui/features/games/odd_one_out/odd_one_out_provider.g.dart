// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'odd_one_out_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OddOneOutNotifier)
final oddOneOutProvider = OddOneOutNotifierProvider._();

final class OddOneOutNotifierProvider
    extends $NotifierProvider<OddOneOutNotifier, OddOneOutState> {
  OddOneOutNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'oddOneOutProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$oddOneOutNotifierHash();

  @$internal
  @override
  OddOneOutNotifier create() => OddOneOutNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OddOneOutState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OddOneOutState>(value),
    );
  }
}

String _$oddOneOutNotifierHash() => r'6c0bc825b1cf9a53c97c365f72c7759545188dfc';

abstract class _$OddOneOutNotifier extends $Notifier<OddOneOutState> {
  OddOneOutState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<OddOneOutState, OddOneOutState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OddOneOutState, OddOneOutState>,
              OddOneOutState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
