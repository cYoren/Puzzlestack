// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spatial_cabinet_memory_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SpatialCabinetMemoryNotifier)
final spatialCabinetMemoryProvider = SpatialCabinetMemoryNotifierProvider._();

final class SpatialCabinetMemoryNotifierProvider
    extends
        $NotifierProvider<
          SpatialCabinetMemoryNotifier,
          SpatialCabinetMemoryState
        > {
  SpatialCabinetMemoryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'spatialCabinetMemoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$spatialCabinetMemoryNotifierHash();

  @$internal
  @override
  SpatialCabinetMemoryNotifier create() => SpatialCabinetMemoryNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpatialCabinetMemoryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SpatialCabinetMemoryState>(value),
    );
  }
}

String _$spatialCabinetMemoryNotifierHash() =>
    r'86d9bd13c480215ffc13db6cab8098226e632234';

abstract class _$SpatialCabinetMemoryNotifier
    extends $Notifier<SpatialCabinetMemoryState> {
  SpatialCabinetMemoryState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<SpatialCabinetMemoryState, SpatialCabinetMemoryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SpatialCabinetMemoryState, SpatialCabinetMemoryState>,
              SpatialCabinetMemoryState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
