// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_scramble_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WordScrambleNotifier)
final wordScrambleProvider = WordScrambleNotifierProvider._();

final class WordScrambleNotifierProvider
    extends $NotifierProvider<WordScrambleNotifier, WordScrambleState> {
  WordScrambleNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wordScrambleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wordScrambleNotifierHash();

  @$internal
  @override
  WordScrambleNotifier create() => WordScrambleNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WordScrambleState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WordScrambleState>(value),
    );
  }
}

String _$wordScrambleNotifierHash() =>
    r'bbe4a5446db38bd8ec2744f6659236f4c9e57390';

abstract class _$WordScrambleNotifier extends $Notifier<WordScrambleState> {
  WordScrambleState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<WordScrambleState, WordScrambleState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WordScrambleState, WordScrambleState>,
              WordScrambleState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
