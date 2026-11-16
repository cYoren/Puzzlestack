// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mirror_tracing_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MirrorTracingNotifier)
final mirrorTracingProvider = MirrorTracingNotifierProvider._();

final class MirrorTracingNotifierProvider
    extends $NotifierProvider<MirrorTracingNotifier, MirrorTracingState> {
  MirrorTracingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mirrorTracingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mirrorTracingNotifierHash();

  @$internal
  @override
  MirrorTracingNotifier create() => MirrorTracingNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MirrorTracingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MirrorTracingState>(value),
    );
  }
}

String _$mirrorTracingNotifierHash() =>
    r'd6c28bf747c0e581f398c10e7911b2f163a61f30';

abstract class _$MirrorTracingNotifier extends $Notifier<MirrorTracingState> {
  MirrorTracingState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MirrorTracingState, MirrorTracingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MirrorTracingState, MirrorTracingState>,
              MirrorTracingState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
