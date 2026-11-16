// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sentence_unscramble_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SentenceUnscrambleNotifier)
final sentenceUnscrambleProvider = SentenceUnscrambleNotifierProvider._();

final class SentenceUnscrambleNotifierProvider
    extends
        $NotifierProvider<SentenceUnscrambleNotifier, SentenceUnscrambleState> {
  SentenceUnscrambleNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sentenceUnscrambleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sentenceUnscrambleNotifierHash();

  @$internal
  @override
  SentenceUnscrambleNotifier create() => SentenceUnscrambleNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SentenceUnscrambleState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SentenceUnscrambleState>(value),
    );
  }
}

String _$sentenceUnscrambleNotifierHash() =>
    r'46c99d30105c3cf4df5b4848f317f7fa2d5724c4';

abstract class _$SentenceUnscrambleNotifier
    extends $Notifier<SentenceUnscrambleState> {
  SentenceUnscrambleState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<SentenceUnscrambleState, SentenceUnscrambleState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SentenceUnscrambleState, SentenceUnscrambleState>,
              SentenceUnscrambleState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
