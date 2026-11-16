// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sudoku_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SudokuNotifier)
final sudokuProvider = SudokuNotifierProvider._();

final class SudokuNotifierProvider
    extends $AsyncNotifierProvider<SudokuNotifier, SudokuState> {
  SudokuNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sudokuProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sudokuNotifierHash();

  @$internal
  @override
  SudokuNotifier create() => SudokuNotifier();
}

String _$sudokuNotifierHash() => r'711d0d3936b5ac2727223f29846f17b909b0e53f';

abstract class _$SudokuNotifier extends $AsyncNotifier<SudokuState> {
  FutureOr<SudokuState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SudokuState>, SudokuState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SudokuState>, SudokuState>,
              AsyncValue<SudokuState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
