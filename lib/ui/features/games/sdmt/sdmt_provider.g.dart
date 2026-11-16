// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sdmt_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SdmtNotifier)
final sdmtProvider = SdmtNotifierProvider._();

final class SdmtNotifierProvider
    extends $NotifierProvider<SdmtNotifier, SdmtState> {
  SdmtNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sdmtProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sdmtNotifierHash();

  @$internal
  @override
  SdmtNotifier create() => SdmtNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SdmtState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SdmtState>(value),
    );
  }
}

String _$sdmtNotifierHash() => r'74a2dc8105075c59d5937be6621e307b2222b029';

abstract class _$SdmtNotifier extends $Notifier<SdmtState> {
  SdmtState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SdmtState, SdmtState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SdmtState, SdmtState>,
              SdmtState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
