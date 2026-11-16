// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kenken_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(KenKenNotifier)
final kenKenProvider = KenKenNotifierProvider._();

final class KenKenNotifierProvider
    extends $NotifierProvider<KenKenNotifier, KenKenState> {
  KenKenNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kenKenProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kenKenNotifierHash();

  @$internal
  @override
  KenKenNotifier create() => KenKenNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KenKenState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KenKenState>(value),
    );
  }
}

String _$kenKenNotifierHash() => r'5f351996efe015bb69fc9957a00b15efe355adf5';

abstract class _$KenKenNotifier extends $Notifier<KenKenState> {
  KenKenState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<KenKenState, KenKenState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<KenKenState, KenKenState>,
              KenKenState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
