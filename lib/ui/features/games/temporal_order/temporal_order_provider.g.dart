// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'temporal_order_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TemporalOrderNotifier)
final temporalOrderProvider = TemporalOrderNotifierProvider._();

final class TemporalOrderNotifierProvider
    extends $NotifierProvider<TemporalOrderNotifier, TemporalOrderState> {
  TemporalOrderNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'temporalOrderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$temporalOrderNotifierHash();

  @$internal
  @override
  TemporalOrderNotifier create() => TemporalOrderNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TemporalOrderState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TemporalOrderState>(value),
    );
  }
}

String _$temporalOrderNotifierHash() =>
    r'a35dd79d6cba2668e6fd5b4bdfc6ae58ffcf1aa8';

abstract class _$TemporalOrderNotifier extends $Notifier<TemporalOrderState> {
  TemporalOrderState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TemporalOrderState, TemporalOrderState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TemporalOrderState, TemporalOrderState>,
              TemporalOrderState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
