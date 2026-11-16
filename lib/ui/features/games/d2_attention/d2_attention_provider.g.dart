// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'd2_attention_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(D2AttentionNotifier)
final d2AttentionProvider = D2AttentionNotifierProvider._();

final class D2AttentionNotifierProvider
    extends $NotifierProvider<D2AttentionNotifier, D2AttentionState> {
  D2AttentionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'd2AttentionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$d2AttentionNotifierHash();

  @$internal
  @override
  D2AttentionNotifier create() => D2AttentionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(D2AttentionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<D2AttentionState>(value),
    );
  }
}

String _$d2AttentionNotifierHash() =>
    r'f9b9525a068bbc4a9a10d4b98d27b5e21c12a5ba';

abstract class _$D2AttentionNotifier extends $Notifier<D2AttentionState> {
  D2AttentionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<D2AttentionState, D2AttentionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<D2AttentionState, D2AttentionState>,
              D2AttentionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
