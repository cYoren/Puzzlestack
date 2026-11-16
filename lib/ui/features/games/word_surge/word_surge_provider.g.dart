// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_surge_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WordSurgeNotifier)
final wordSurgeProvider = WordSurgeNotifierProvider._();

final class WordSurgeNotifierProvider
    extends $NotifierProvider<WordSurgeNotifier, WordSurgeState> {
  WordSurgeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wordSurgeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wordSurgeNotifierHash();

  @$internal
  @override
  WordSurgeNotifier create() => WordSurgeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WordSurgeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WordSurgeState>(value),
    );
  }
}

String _$wordSurgeNotifierHash() => r'f877af7deb2dfb5bf87c46333c4276f3e6138e45';

abstract class _$WordSurgeNotifier extends $Notifier<WordSurgeState> {
  WordSurgeState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<WordSurgeState, WordSurgeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WordSurgeState, WordSurgeState>,
              WordSurgeState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
