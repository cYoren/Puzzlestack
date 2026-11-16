// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interlock_puzzle_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(InterlockPuzzleNotifier)
final interlockPuzzleProvider = InterlockPuzzleNotifierProvider._();

final class InterlockPuzzleNotifierProvider
    extends $NotifierProvider<InterlockPuzzleNotifier, InterlockPuzzleState> {
  InterlockPuzzleNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'interlockPuzzleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$interlockPuzzleNotifierHash();

  @$internal
  @override
  InterlockPuzzleNotifier create() => InterlockPuzzleNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InterlockPuzzleState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InterlockPuzzleState>(value),
    );
  }
}

String _$interlockPuzzleNotifierHash() =>
    r'b79a8763240b791ee548d206e3a75d558ea18952';

abstract class _$InterlockPuzzleNotifier
    extends $Notifier<InterlockPuzzleState> {
  InterlockPuzzleState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<InterlockPuzzleState, InterlockPuzzleState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InterlockPuzzleState, InterlockPuzzleState>,
              InterlockPuzzleState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
