// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alphabet_sudoku_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AlphabetSudokuNotifier)
final alphabetSudokuProvider = AlphabetSudokuNotifierProvider._();

final class AlphabetSudokuNotifierProvider
    extends
        $AsyncNotifierProvider<AlphabetSudokuNotifier, AlphabetSudokuState> {
  AlphabetSudokuNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alphabetSudokuProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alphabetSudokuNotifierHash();

  @$internal
  @override
  AlphabetSudokuNotifier create() => AlphabetSudokuNotifier();
}

String _$alphabetSudokuNotifierHash() =>
    r'5737c2dfe6a53c0fb4440c15060242f60dd9fe67';

abstract class _$AlphabetSudokuNotifier
    extends $AsyncNotifier<AlphabetSudokuState> {
  FutureOr<AlphabetSudokuState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<AlphabetSudokuState>, AlphabetSudokuState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AlphabetSudokuState>, AlphabetSudokuState>,
              AsyncValue<AlphabetSudokuState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
