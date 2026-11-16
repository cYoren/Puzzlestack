// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_matrix_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MemoryMatrixNotifier)
final memoryMatrixProvider = MemoryMatrixNotifierProvider._();

final class MemoryMatrixNotifierProvider
    extends $NotifierProvider<MemoryMatrixNotifier, MemoryMatrixState> {
  MemoryMatrixNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memoryMatrixProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memoryMatrixNotifierHash();

  @$internal
  @override
  MemoryMatrixNotifier create() => MemoryMatrixNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MemoryMatrixState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MemoryMatrixState>(value),
    );
  }
}

String _$memoryMatrixNotifierHash() =>
    r'5f873e271c0035f053f7fed52e59feb31017cf9b';

abstract class _$MemoryMatrixNotifier extends $Notifier<MemoryMatrixState> {
  MemoryMatrixState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MemoryMatrixState, MemoryMatrixState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MemoryMatrixState, MemoryMatrixState>,
              MemoryMatrixState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
