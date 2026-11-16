// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'water_sort_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WaterSortNotifier)
final waterSortProvider = WaterSortNotifierProvider._();

final class WaterSortNotifierProvider
    extends $NotifierProvider<WaterSortNotifier, WaterSortState> {
  WaterSortNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'waterSortProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$waterSortNotifierHash();

  @$internal
  @override
  WaterSortNotifier create() => WaterSortNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WaterSortState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WaterSortState>(value),
    );
  }
}

String _$waterSortNotifierHash() => r'6f62cc213af90ab793697111c7b5f9c3788dc90e';

abstract class _$WaterSortNotifier extends $Notifier<WaterSortState> {
  WaterSortState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<WaterSortState, WaterSortState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WaterSortState, WaterSortState>,
              WaterSortState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
