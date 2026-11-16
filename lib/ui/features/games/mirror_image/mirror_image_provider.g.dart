// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mirror_image_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MirrorImageNotifier)
final mirrorImageProvider = MirrorImageNotifierProvider._();

final class MirrorImageNotifierProvider
    extends $NotifierProvider<MirrorImageNotifier, MirrorImageState> {
  MirrorImageNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mirrorImageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mirrorImageNotifierHash();

  @$internal
  @override
  MirrorImageNotifier create() => MirrorImageNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MirrorImageState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MirrorImageState>(value),
    );
  }
}

String _$mirrorImageNotifierHash() =>
    r'205a2cf998a550459c2f02d7f77c3e2aeb029d52';

abstract class _$MirrorImageNotifier extends $Notifier<MirrorImageState> {
  MirrorImageState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MirrorImageState, MirrorImageState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MirrorImageState, MirrorImageState>,
              MirrorImageState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
