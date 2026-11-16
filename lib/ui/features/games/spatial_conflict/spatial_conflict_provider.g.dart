// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spatial_conflict_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SpatialConflictNotifier)
final spatialConflictProvider = SpatialConflictNotifierProvider._();

final class SpatialConflictNotifierProvider
    extends $NotifierProvider<SpatialConflictNotifier, SpatialConflictState> {
  SpatialConflictNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'spatialConflictProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$spatialConflictNotifierHash();

  @$internal
  @override
  SpatialConflictNotifier create() => SpatialConflictNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpatialConflictState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SpatialConflictState>(value),
    );
  }
}

String _$spatialConflictNotifierHash() =>
    r'9eac352510461065ea2a0fde241e6d8a48b606d2';

abstract class _$SpatialConflictNotifier
    extends $Notifier<SpatialConflictState> {
  SpatialConflictState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SpatialConflictState, SpatialConflictState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SpatialConflictState, SpatialConflictState>,
              SpatialConflictState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
