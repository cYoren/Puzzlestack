// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cryptogram_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CryptogramNotifier)
final cryptogramProvider = CryptogramNotifierProvider._();

final class CryptogramNotifierProvider
    extends $NotifierProvider<CryptogramNotifier, CryptogramState> {
  CryptogramNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cryptogramProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cryptogramNotifierHash();

  @$internal
  @override
  CryptogramNotifier create() => CryptogramNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CryptogramState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CryptogramState>(value),
    );
  }
}

String _$cryptogramNotifierHash() =>
    r'360c8ca16d88b4ec1ae9973bb6f4d13f519c658d';

abstract class _$CryptogramNotifier extends $Notifier<CryptogramState> {
  CryptogramState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CryptogramState, CryptogramState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CryptogramState, CryptogramState>,
              CryptogramState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
