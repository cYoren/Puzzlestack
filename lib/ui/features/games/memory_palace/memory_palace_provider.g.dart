// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_palace_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MemoryPalaceNotifier)
final memoryPalaceProvider = MemoryPalaceNotifierProvider._();

final class MemoryPalaceNotifierProvider
    extends $NotifierProvider<MemoryPalaceNotifier, MemoryPalaceState> {
  MemoryPalaceNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memoryPalaceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memoryPalaceNotifierHash();

  @$internal
  @override
  MemoryPalaceNotifier create() => MemoryPalaceNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MemoryPalaceState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MemoryPalaceState>(value),
    );
  }
}

String _$memoryPalaceNotifierHash() =>
    r'3ea7fdbc3350711f3f9250441df0c5c99c2ef8c0';

abstract class _$MemoryPalaceNotifier extends $Notifier<MemoryPalaceState> {
  MemoryPalaceState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MemoryPalaceState, MemoryPalaceState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MemoryPalaceState, MemoryPalaceState>,
              MemoryPalaceState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
