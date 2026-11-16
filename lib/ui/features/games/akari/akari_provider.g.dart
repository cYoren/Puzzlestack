// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'akari_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AkariNotifier)
final akariProvider = AkariNotifierProvider._();

final class AkariNotifierProvider
    extends $NotifierProvider<AkariNotifier, AkariState> {
  AkariNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'akariProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$akariNotifierHash();

  @$internal
  @override
  AkariNotifier create() => AkariNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AkariState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AkariState>(value),
    );
  }
}

String _$akariNotifierHash() => r'7eb7254d1313008740419d5cf5eb732f0896e57c';

abstract class _$AkariNotifier extends $Notifier<AkariState> {
  AkariState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AkariState, AkariState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AkariState, AkariState>,
              AkariState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
