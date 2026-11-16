// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lights_out_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LightsOutNotifier)
final lightsOutProvider = LightsOutNotifierProvider._();

final class LightsOutNotifierProvider
    extends $NotifierProvider<LightsOutNotifier, LightsOutState> {
  LightsOutNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lightsOutProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lightsOutNotifierHash();

  @$internal
  @override
  LightsOutNotifier create() => LightsOutNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LightsOutState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LightsOutState>(value),
    );
  }
}

String _$lightsOutNotifierHash() => r'53b85e4d053f6cdf16e61d12a24b09a9826a03e8';

abstract class _$LightsOutNotifier extends $Notifier<LightsOutState> {
  LightsOutState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LightsOutState, LightsOutState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LightsOutState, LightsOutState>,
              LightsOutState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
