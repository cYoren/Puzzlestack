// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'corsi_blocks_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CorsiBlocksNotifier)
final corsiBlocksProvider = CorsiBlocksNotifierProvider._();

final class CorsiBlocksNotifierProvider
    extends $NotifierProvider<CorsiBlocksNotifier, CorsiBlocksState> {
  CorsiBlocksNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'corsiBlocksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$corsiBlocksNotifierHash();

  @$internal
  @override
  CorsiBlocksNotifier create() => CorsiBlocksNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CorsiBlocksState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CorsiBlocksState>(value),
    );
  }
}

String _$corsiBlocksNotifierHash() =>
    r'29064239ec2fa535ee181d5e0fd0474ff8e6b226';

abstract class _$CorsiBlocksNotifier extends $Notifier<CorsiBlocksState> {
  CorsiBlocksState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CorsiBlocksState, CorsiBlocksState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CorsiBlocksState, CorsiBlocksState>,
              CorsiBlocksState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
