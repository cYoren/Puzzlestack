// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kurodoko_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(KurodokoNotifier)
final kurodokoProvider = KurodokoNotifierProvider._();

final class KurodokoNotifierProvider
    extends $NotifierProvider<KurodokoNotifier, KurodokoState> {
  KurodokoNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kurodokoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kurodokoNotifierHash();

  @$internal
  @override
  KurodokoNotifier create() => KurodokoNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KurodokoState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KurodokoState>(value),
    );
  }
}

String _$kurodokoNotifierHash() => r'e76df30099b8c74eb3f35cd941b636fc07d25bba';

abstract class _$KurodokoNotifier extends $Notifier<KurodokoState> {
  KurodokoState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<KurodokoState, KurodokoState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<KurodokoState, KurodokoState>,
              KurodokoState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
