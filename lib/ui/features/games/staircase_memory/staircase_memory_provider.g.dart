// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staircase_memory_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(StaircaseMemoryNotifier)
final staircaseMemoryProvider = StaircaseMemoryNotifierProvider._();

final class StaircaseMemoryNotifierProvider
    extends $NotifierProvider<StaircaseMemoryNotifier, StaircaseState> {
  StaircaseMemoryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'staircaseMemoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$staircaseMemoryNotifierHash();

  @$internal
  @override
  StaircaseMemoryNotifier create() => StaircaseMemoryNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StaircaseState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StaircaseState>(value),
    );
  }
}

String _$staircaseMemoryNotifierHash() =>
    r'5469ea4ab4ac24a0aa4d18e9bec1673186da032c';

abstract class _$StaircaseMemoryNotifier extends $Notifier<StaircaseState> {
  StaircaseState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<StaircaseState, StaircaseState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<StaircaseState, StaircaseState>,
              StaircaseState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
