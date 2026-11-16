// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'letter_cancellation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LetterCancellationNotifier)
final letterCancellationProvider = LetterCancellationNotifierProvider._();

final class LetterCancellationNotifierProvider
    extends
        $NotifierProvider<LetterCancellationNotifier, LetterCancellationState> {
  LetterCancellationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'letterCancellationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$letterCancellationNotifierHash();

  @$internal
  @override
  LetterCancellationNotifier create() => LetterCancellationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LetterCancellationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LetterCancellationState>(value),
    );
  }
}

String _$letterCancellationNotifierHash() =>
    r'8c3dcfe29a5122b2bdf2684c585f7fca792ea0a2';

abstract class _$LetterCancellationNotifier
    extends $Notifier<LetterCancellationState> {
  LetterCancellationState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<LetterCancellationState, LetterCancellationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LetterCancellationState, LetterCancellationState>,
              LetterCancellationState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
