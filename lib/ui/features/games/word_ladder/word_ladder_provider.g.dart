// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_ladder_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WordLadderNotifier)
final wordLadderProvider = WordLadderNotifierProvider._();

final class WordLadderNotifierProvider
    extends $NotifierProvider<WordLadderNotifier, WordLadderState> {
  WordLadderNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wordLadderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wordLadderNotifierHash();

  @$internal
  @override
  WordLadderNotifier create() => WordLadderNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WordLadderState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WordLadderState>(value),
    );
  }
}

String _$wordLadderNotifierHash() =>
    r'54c56e5c2f08c34502a559324c226987edd519f4';

abstract class _$WordLadderNotifier extends $Notifier<WordLadderState> {
  WordLadderState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<WordLadderState, WordLadderState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WordLadderState, WordLadderState>,
              WordLadderState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
