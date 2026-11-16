// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cross_section_slice_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CrossSectionSliceNotifier)
final crossSectionSliceProvider = CrossSectionSliceNotifierProvider._();

final class CrossSectionSliceNotifierProvider
    extends
        $NotifierProvider<CrossSectionSliceNotifier, CrossSectionSliceState> {
  CrossSectionSliceNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'crossSectionSliceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$crossSectionSliceNotifierHash();

  @$internal
  @override
  CrossSectionSliceNotifier create() => CrossSectionSliceNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CrossSectionSliceState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CrossSectionSliceState>(value),
    );
  }
}

String _$crossSectionSliceNotifierHash() =>
    r'995146a0f3864bba0c941d0d3da805de9ac442dd';

abstract class _$CrossSectionSliceNotifier
    extends $Notifier<CrossSectionSliceState> {
  CrossSectionSliceState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<CrossSectionSliceState, CrossSectionSliceState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CrossSectionSliceState, CrossSectionSliceState>,
              CrossSectionSliceState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
