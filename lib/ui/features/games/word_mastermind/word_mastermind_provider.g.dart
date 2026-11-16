// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_mastermind_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WordMastermindNotifier)
final wordMastermindProvider = WordMastermindNotifierProvider._();

final class WordMastermindNotifierProvider
    extends $NotifierProvider<WordMastermindNotifier, WordMastermindState> {
  WordMastermindNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wordMastermindProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wordMastermindNotifierHash();

  @$internal
  @override
  WordMastermindNotifier create() => WordMastermindNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WordMastermindState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WordMastermindState>(value),
    );
  }
}

String _$wordMastermindNotifierHash() =>
    r'7e87014adc85c6cdb879c7a4db101bffbf716760';

abstract class _$WordMastermindNotifier extends $Notifier<WordMastermindState> {
  WordMastermindState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<WordMastermindState, WordMastermindState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WordMastermindState, WordMastermindState>,
              WordMastermindState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
