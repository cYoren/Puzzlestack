// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'binary_puzzle_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BinaryPuzzleNotifier)
final binaryPuzzleProvider = BinaryPuzzleNotifierProvider._();

final class BinaryPuzzleNotifierProvider
    extends $NotifierProvider<BinaryPuzzleNotifier, BinaryPuzzleState> {
  BinaryPuzzleNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'binaryPuzzleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$binaryPuzzleNotifierHash();

  @$internal
  @override
  BinaryPuzzleNotifier create() => BinaryPuzzleNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BinaryPuzzleState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BinaryPuzzleState>(value),
    );
  }
}

String _$binaryPuzzleNotifierHash() =>
    r'5ebb72bde01e93ed8a6662ed84bd4d4b2efd361c';

abstract class _$BinaryPuzzleNotifier extends $Notifier<BinaryPuzzleState> {
  BinaryPuzzleState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BinaryPuzzleState, BinaryPuzzleState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BinaryPuzzleState, BinaryPuzzleState>,
              BinaryPuzzleState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
