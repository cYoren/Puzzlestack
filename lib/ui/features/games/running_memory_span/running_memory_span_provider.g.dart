// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'running_memory_span_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RunningMemorySpanNotifier)
final runningMemorySpanProvider = RunningMemorySpanNotifierProvider._();

final class RunningMemorySpanNotifierProvider
    extends
        $NotifierProvider<RunningMemorySpanNotifier, RunningMemorySpanState> {
  RunningMemorySpanNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'runningMemorySpanProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$runningMemorySpanNotifierHash();

  @$internal
  @override
  RunningMemorySpanNotifier create() => RunningMemorySpanNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RunningMemorySpanState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RunningMemorySpanState>(value),
    );
  }
}

String _$runningMemorySpanNotifierHash() =>
    r'e6dc3ef4d6ab9922a6a74918ebe25cd7a6ca23cb';

abstract class _$RunningMemorySpanNotifier
    extends $Notifier<RunningMemorySpanState> {
  RunningMemorySpanState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<RunningMemorySpanState, RunningMemorySpanState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RunningMemorySpanState, RunningMemorySpanState>,
              RunningMemorySpanState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
