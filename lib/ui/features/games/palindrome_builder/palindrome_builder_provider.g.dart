// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'palindrome_builder_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PalindromeBuilderNotifier)
final palindromeBuilderProvider = PalindromeBuilderNotifierProvider._();

final class PalindromeBuilderNotifierProvider
    extends
        $NotifierProvider<PalindromeBuilderNotifier, PalindromeBuilderState> {
  PalindromeBuilderNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'palindromeBuilderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$palindromeBuilderNotifierHash();

  @$internal
  @override
  PalindromeBuilderNotifier create() => PalindromeBuilderNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PalindromeBuilderState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PalindromeBuilderState>(value),
    );
  }
}

String _$palindromeBuilderNotifierHash() =>
    r'5f485961e3eff9932933deae266ce35726210b0b';

abstract class _$PalindromeBuilderNotifier
    extends $Notifier<PalindromeBuilderState> {
  PalindromeBuilderState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<PalindromeBuilderState, PalindromeBuilderState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PalindromeBuilderState, PalindromeBuilderState>,
              PalindromeBuilderState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
