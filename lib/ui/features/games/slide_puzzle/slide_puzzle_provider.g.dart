// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slide_puzzle_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SlidePuzzleNotifier)
final slidePuzzleProvider = SlidePuzzleNotifierProvider._();

final class SlidePuzzleNotifierProvider
    extends $NotifierProvider<SlidePuzzleNotifier, SlidePuzzleState> {
  SlidePuzzleNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'slidePuzzleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$slidePuzzleNotifierHash();

  @$internal
  @override
  SlidePuzzleNotifier create() => SlidePuzzleNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SlidePuzzleState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SlidePuzzleState>(value),
    );
  }
}

String _$slidePuzzleNotifierHash() =>
    r'2fda0b3625a357f439d3196ff27a0cf05f60ba22';

abstract class _$SlidePuzzleNotifier extends $Notifier<SlidePuzzleState> {
  SlidePuzzleState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SlidePuzzleState, SlidePuzzleState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SlidePuzzleState, SlidePuzzleState>,
              SlidePuzzleState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
