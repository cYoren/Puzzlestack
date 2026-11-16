// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'color_match_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ColorMatchNotifier)
final colorMatchProvider = ColorMatchNotifierProvider._();

final class ColorMatchNotifierProvider
    extends $NotifierProvider<ColorMatchNotifier, ColorMatchState> {
  ColorMatchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'colorMatchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$colorMatchNotifierHash();

  @$internal
  @override
  ColorMatchNotifier create() => ColorMatchNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ColorMatchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ColorMatchState>(value),
    );
  }
}

String _$colorMatchNotifierHash() =>
    r'68b3847dd38fa469636a66e5f4f331cb2aa0ab1d';

abstract class _$ColorMatchNotifier extends $Notifier<ColorMatchState> {
  ColorMatchState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ColorMatchState, ColorMatchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ColorMatchState, ColorMatchState>,
              ColorMatchState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
