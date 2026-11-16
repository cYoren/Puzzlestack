// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WordSearchNotifier)
final wordSearchProvider = WordSearchNotifierProvider._();

final class WordSearchNotifierProvider
    extends $NotifierProvider<WordSearchNotifier, WordSearchState> {
  WordSearchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wordSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wordSearchNotifierHash();

  @$internal
  @override
  WordSearchNotifier create() => WordSearchNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WordSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WordSearchState>(value),
    );
  }
}

String _$wordSearchNotifierHash() =>
    r'2f89636820015dcc3d78857ad06a4605b7f82160';

abstract class _$WordSearchNotifier extends $Notifier<WordSearchState> {
  WordSearchState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<WordSearchState, WordSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WordSearchState, WordSearchState>,
              WordSearchState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
