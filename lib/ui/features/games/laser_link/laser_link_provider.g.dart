// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'laser_link_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LaserLinkNotifier)
final laserLinkProvider = LaserLinkNotifierProvider._();

final class LaserLinkNotifierProvider
    extends $NotifierProvider<LaserLinkNotifier, LaserLinkState> {
  LaserLinkNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'laserLinkProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$laserLinkNotifierHash();

  @$internal
  @override
  LaserLinkNotifier create() => LaserLinkNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LaserLinkState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LaserLinkState>(value),
    );
  }
}

String _$laserLinkNotifierHash() => r'e4147b96d835d855739ec010747ace51a2ddd472';

abstract class _$LaserLinkNotifier extends $Notifier<LaserLinkState> {
  LaserLinkState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LaserLinkState, LaserLinkState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LaserLinkState, LaserLinkState>,
              LaserLinkState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
