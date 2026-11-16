// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dual_mirror_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DualMirrorNotifier)
final dualMirrorProvider = DualMirrorNotifierProvider._();

final class DualMirrorNotifierProvider
    extends $NotifierProvider<DualMirrorNotifier, DualMirrorState> {
  DualMirrorNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dualMirrorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dualMirrorNotifierHash();

  @$internal
  @override
  DualMirrorNotifier create() => DualMirrorNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DualMirrorState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DualMirrorState>(value),
    );
  }
}

String _$dualMirrorNotifierHash() =>
    r'597ec22e168f402ab422fb5a91d185d29c6bdbf9';

abstract class _$DualMirrorNotifier extends $Notifier<DualMirrorState> {
  DualMirrorState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DualMirrorState, DualMirrorState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DualMirrorState, DualMirrorState>,
              DualMirrorState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
