// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compound_connect_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CompoundConnectNotifier)
final compoundConnectProvider = CompoundConnectNotifierProvider._();

final class CompoundConnectNotifierProvider
    extends $NotifierProvider<CompoundConnectNotifier, CompoundConnectState> {
  CompoundConnectNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'compoundConnectProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$compoundConnectNotifierHash();

  @$internal
  @override
  CompoundConnectNotifier create() => CompoundConnectNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CompoundConnectState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CompoundConnectState>(value),
    );
  }
}

String _$compoundConnectNotifierHash() =>
    r'ba79d408721cbc40be75a7aeff951f877bddd5a0';

abstract class _$CompoundConnectNotifier
    extends $Notifier<CompoundConnectState> {
  CompoundConnectState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CompoundConnectState, CompoundConnectState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CompoundConnectState, CompoundConnectState>,
              CompoundConnectState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
