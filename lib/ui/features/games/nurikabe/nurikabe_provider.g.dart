// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nurikabe_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NurikabeNotifier)
final nurikabeProvider = NurikabeNotifierProvider._();

final class NurikabeNotifierProvider
    extends $NotifierProvider<NurikabeNotifier, NurikabeState> {
  NurikabeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nurikabeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nurikabeNotifierHash();

  @$internal
  @override
  NurikabeNotifier create() => NurikabeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NurikabeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NurikabeState>(value),
    );
  }
}

String _$nurikabeNotifierHash() => r'fb3d39b63b0b0b01870144c97febf4cb19d96a56';

abstract class _$NurikabeNotifier extends $Notifier<NurikabeState> {
  NurikabeState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NurikabeState, NurikabeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NurikabeState, NurikabeState>,
              NurikabeState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
