// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spotlight_track_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SpotlightTrackNotifier)
final spotlightTrackProvider = SpotlightTrackNotifierProvider._();

final class SpotlightTrackNotifierProvider
    extends $NotifierProvider<SpotlightTrackNotifier, SpotlightTrackState> {
  SpotlightTrackNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'spotlightTrackProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$spotlightTrackNotifierHash();

  @$internal
  @override
  SpotlightTrackNotifier create() => SpotlightTrackNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpotlightTrackState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SpotlightTrackState>(value),
    );
  }
}

String _$spotlightTrackNotifierHash() =>
    r'266cd7383850f429914ce2505ab3d93e2ca1872e';

abstract class _$SpotlightTrackNotifier extends $Notifier<SpotlightTrackState> {
  SpotlightTrackState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SpotlightTrackState, SpotlightTrackState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SpotlightTrackState, SpotlightTrackState>,
              SpotlightTrackState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
