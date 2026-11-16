// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etymology_origin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EtymologyOriginNotifier)
final etymologyOriginProvider = EtymologyOriginNotifierProvider._();

final class EtymologyOriginNotifierProvider
    extends $NotifierProvider<EtymologyOriginNotifier, EtymologyOriginState> {
  EtymologyOriginNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'etymologyOriginProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$etymologyOriginNotifierHash();

  @$internal
  @override
  EtymologyOriginNotifier create() => EtymologyOriginNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EtymologyOriginState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EtymologyOriginState>(value),
    );
  }
}

String _$etymologyOriginNotifierHash() =>
    r'f0ef987a7da24177d13584fc7c00f9e676671cea';

abstract class _$EtymologyOriginNotifier
    extends $Notifier<EtymologyOriginState> {
  EtymologyOriginState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EtymologyOriginState, EtymologyOriginState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EtymologyOriginState, EtymologyOriginState>,
              EtymologyOriginState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
