// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'galaxies_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GalaxiesNotifier)
final galaxiesProvider = GalaxiesNotifierProvider._();

final class GalaxiesNotifierProvider
    extends $NotifierProvider<GalaxiesNotifier, GalaxiesState> {
  GalaxiesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'galaxiesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$galaxiesNotifierHash();

  @$internal
  @override
  GalaxiesNotifier create() => GalaxiesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GalaxiesState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GalaxiesState>(value),
    );
  }
}

String _$galaxiesNotifierHash() => r'7235bc3a826ad57649c5729120c7f8f0f540b022';

abstract class _$GalaxiesNotifier extends $Notifier<GalaxiesState> {
  GalaxiesState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<GalaxiesState, GalaxiesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GalaxiesState, GalaxiesState>,
              GalaxiesState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
