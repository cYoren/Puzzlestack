// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chain_reaction_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChainReactionNotifier)
final chainReactionProvider = ChainReactionNotifierProvider._();

final class ChainReactionNotifierProvider
    extends $NotifierProvider<ChainReactionNotifier, ChainReactionState> {
  ChainReactionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chainReactionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chainReactionNotifierHash();

  @$internal
  @override
  ChainReactionNotifier create() => ChainReactionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChainReactionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChainReactionState>(value),
    );
  }
}

String _$chainReactionNotifierHash() =>
    r'02e8e2f68c418997d1b8580877e7fe085b1ab879';

abstract class _$ChainReactionNotifier extends $Notifier<ChainReactionState> {
  ChainReactionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ChainReactionState, ChainReactionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChainReactionState, ChainReactionState>,
              ChainReactionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
