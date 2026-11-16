// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'find_word_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FindWordNotifier)
final findWordProvider = FindWordNotifierProvider._();

final class FindWordNotifierProvider
    extends $NotifierProvider<FindWordNotifier, FindWordState> {
  FindWordNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'findWordProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$findWordNotifierHash();

  @$internal
  @override
  FindWordNotifier create() => FindWordNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FindWordState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FindWordState>(value),
    );
  }
}

String _$findWordNotifierHash() => r'61dac122d970f94457d3b4ec18e1f1a1479cab43';

abstract class _$FindWordNotifier extends $Notifier<FindWordState> {
  FindWordState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FindWordState, FindWordState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FindWordState, FindWordState>,
              FindWordState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
