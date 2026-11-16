// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trail_making_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TrailMakingNotifier)
final trailMakingProvider = TrailMakingNotifierProvider._();

final class TrailMakingNotifierProvider
    extends $NotifierProvider<TrailMakingNotifier, TrailMakingState> {
  TrailMakingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trailMakingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trailMakingNotifierHash();

  @$internal
  @override
  TrailMakingNotifier create() => TrailMakingNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrailMakingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrailMakingState>(value),
    );
  }
}

String _$trailMakingNotifierHash() =>
    r'f676ac5ed2c3d9ea10affaebc7c51bd4e0a6abb8';

abstract class _$TrailMakingNotifier extends $Notifier<TrailMakingState> {
  TrailMakingState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TrailMakingState, TrailMakingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TrailMakingState, TrailMakingState>,
              TrailMakingState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
