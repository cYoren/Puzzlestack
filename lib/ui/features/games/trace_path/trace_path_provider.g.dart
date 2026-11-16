// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trace_path_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TracePathNotifier)
final tracePathProvider = TracePathNotifierProvider._();

final class TracePathNotifierProvider
    extends $NotifierProvider<TracePathNotifier, TracePathState> {
  TracePathNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tracePathProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tracePathNotifierHash();

  @$internal
  @override
  TracePathNotifier create() => TracePathNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TracePathState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TracePathState>(value),
    );
  }
}

String _$tracePathNotifierHash() => r'277e919bb2f032ae28f38c444c5bd51d60852283';

abstract class _$TracePathNotifier extends $Notifier<TracePathState> {
  TracePathState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TracePathState, TracePathState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TracePathState, TracePathState>,
              TracePathState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
