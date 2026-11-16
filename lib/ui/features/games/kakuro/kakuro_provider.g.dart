// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kakuro_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(KakuroNotifier)
final kakuroProvider = KakuroNotifierProvider._();

final class KakuroNotifierProvider
    extends $NotifierProvider<KakuroNotifier, KakuroState> {
  KakuroNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kakuroProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kakuroNotifierHash();

  @$internal
  @override
  KakuroNotifier create() => KakuroNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KakuroState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KakuroState>(value),
    );
  }
}

String _$kakuroNotifierHash() => r'9c7bbb94e25bbac95e76e3c8a85af78f31dd7a2f';

abstract class _$KakuroNotifier extends $Notifier<KakuroState> {
  KakuroState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<KakuroState, KakuroState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<KakuroState, KakuroState>,
              KakuroState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
