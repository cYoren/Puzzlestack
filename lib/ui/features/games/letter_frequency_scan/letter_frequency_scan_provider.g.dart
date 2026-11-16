// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'letter_frequency_scan_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LetterFrequencyScanNotifier)
final letterFrequencyScanProvider = LetterFrequencyScanNotifierProvider._();

final class LetterFrequencyScanNotifierProvider
    extends
        $NotifierProvider<
          LetterFrequencyScanNotifier,
          LetterFrequencyScanState
        > {
  LetterFrequencyScanNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'letterFrequencyScanProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$letterFrequencyScanNotifierHash();

  @$internal
  @override
  LetterFrequencyScanNotifier create() => LetterFrequencyScanNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LetterFrequencyScanState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LetterFrequencyScanState>(value),
    );
  }
}

String _$letterFrequencyScanNotifierHash() =>
    r'137c23e9c021f496bc23a0b9613bb53040ff5e41';

abstract class _$LetterFrequencyScanNotifier
    extends $Notifier<LetterFrequencyScanState> {
  LetterFrequencyScanState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<LetterFrequencyScanState, LetterFrequencyScanState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LetterFrequencyScanState, LetterFrequencyScanState>,
              LetterFrequencyScanState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
