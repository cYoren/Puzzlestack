// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sum_pyramid_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SumPyramidNotifier)
final sumPyramidProvider = SumPyramidNotifierProvider._();

final class SumPyramidNotifierProvider
    extends $NotifierProvider<SumPyramidNotifier, SumPyramidState> {
  SumPyramidNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sumPyramidProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sumPyramidNotifierHash();

  @$internal
  @override
  SumPyramidNotifier create() => SumPyramidNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SumPyramidState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SumPyramidState>(value),
    );
  }
}

String _$sumPyramidNotifierHash() =>
    r'430d59d443b63fd21ecadd4b6ac9002837d7cfc1';

abstract class _$SumPyramidNotifier extends $Notifier<SumPyramidState> {
  SumPyramidState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SumPyramidState, SumPyramidState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SumPyramidState, SumPyramidState>,
              SumPyramidState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
