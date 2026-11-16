// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pixel_mimic_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PixelMimicNotifier)
final pixelMimicProvider = PixelMimicNotifierProvider._();

final class PixelMimicNotifierProvider
    extends $NotifierProvider<PixelMimicNotifier, PixelMimicState> {
  PixelMimicNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pixelMimicProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pixelMimicNotifierHash();

  @$internal
  @override
  PixelMimicNotifier create() => PixelMimicNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PixelMimicState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PixelMimicState>(value),
    );
  }
}

String _$pixelMimicNotifierHash() =>
    r'00983999d14f4fcc906d4525e202318d95f9b2c3';

abstract class _$PixelMimicNotifier extends $Notifier<PixelMimicState> {
  PixelMimicState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PixelMimicState, PixelMimicState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PixelMimicState, PixelMimicState>,
              PixelMimicState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
