// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'color_flood_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ColorFloodNotifier)
final colorFloodProvider = ColorFloodNotifierProvider._();

final class ColorFloodNotifierProvider
    extends $NotifierProvider<ColorFloodNotifier, ColorFloodState> {
  ColorFloodNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'colorFloodProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$colorFloodNotifierHash();

  @$internal
  @override
  ColorFloodNotifier create() => ColorFloodNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ColorFloodState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ColorFloodState>(value),
    );
  }
}

String _$colorFloodNotifierHash() =>
    r'8311281d0151aa009e9e3f15a5a69159aefc87c6';

abstract class _$ColorFloodNotifier extends $Notifier<ColorFloodState> {
  ColorFloodState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ColorFloodState, ColorFloodState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ColorFloodState, ColorFloodState>,
              ColorFloodState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
