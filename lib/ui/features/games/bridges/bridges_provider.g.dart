// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bridges_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BridgesNotifier)
final bridgesProvider = BridgesNotifierProvider._();

final class BridgesNotifierProvider
    extends $NotifierProvider<BridgesNotifier, BridgesState> {
  BridgesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bridgesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bridgesNotifierHash();

  @$internal
  @override
  BridgesNotifier create() => BridgesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BridgesState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BridgesState>(value),
    );
  }
}

String _$bridgesNotifierHash() => r'5948f8874bc4db0bc8bab99bfc900ea35abe3a9b';

abstract class _$BridgesNotifier extends $Notifier<BridgesState> {
  BridgesState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BridgesState, BridgesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BridgesState, BridgesState>,
              BridgesState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
