// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'symbol_logic_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SymbolLogicNotifier)
final symbolLogicProvider = SymbolLogicNotifierProvider._();

final class SymbolLogicNotifierProvider
    extends $NotifierProvider<SymbolLogicNotifier, SymbolLogicState> {
  SymbolLogicNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'symbolLogicProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$symbolLogicNotifierHash();

  @$internal
  @override
  SymbolLogicNotifier create() => SymbolLogicNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SymbolLogicState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SymbolLogicState>(value),
    );
  }
}

String _$symbolLogicNotifierHash() =>
    r'4cbb830e0051fcf92064b46c01170f58d526e2e0';

abstract class _$SymbolLogicNotifier extends $Notifier<SymbolLogicState> {
  SymbolLogicState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SymbolLogicState, SymbolLogicState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SymbolLogicState, SymbolLogicState>,
              SymbolLogicState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
