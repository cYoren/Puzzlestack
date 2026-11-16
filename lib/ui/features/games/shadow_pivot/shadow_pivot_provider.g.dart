// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shadow_pivot_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ShadowPivotNotifier)
final shadowPivotProvider = ShadowPivotNotifierProvider._();

final class ShadowPivotNotifierProvider
    extends $NotifierProvider<ShadowPivotNotifier, ShadowPivotState> {
  ShadowPivotNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shadowPivotProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shadowPivotNotifierHash();

  @$internal
  @override
  ShadowPivotNotifier create() => ShadowPivotNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShadowPivotState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShadowPivotState>(value),
    );
  }
}

String _$shadowPivotNotifierHash() =>
    r'003548bf79765d5b3435407ec1019e56b5bfb29e';

abstract class _$ShadowPivotNotifier extends $Notifier<ShadowPivotState> {
  ShadowPivotState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ShadowPivotState, ShadowPivotState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ShadowPivotState, ShadowPivotState>,
              ShadowPivotState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
