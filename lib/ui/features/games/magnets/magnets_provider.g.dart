// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'magnets_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MagnetsNotifier)
final magnetsProvider = MagnetsNotifierProvider._();

final class MagnetsNotifierProvider
    extends $NotifierProvider<MagnetsNotifier, MagnetsState> {
  MagnetsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'magnetsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$magnetsNotifierHash();

  @$internal
  @override
  MagnetsNotifier create() => MagnetsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MagnetsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MagnetsState>(value),
    );
  }
}

String _$magnetsNotifierHash() => r'851e2ed80e3bde3374c7da1766fd7b9b2460552e';

abstract class _$MagnetsNotifier extends $Notifier<MagnetsState> {
  MagnetsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MagnetsState, MagnetsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MagnetsState, MagnetsState>,
              MagnetsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
