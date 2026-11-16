// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block_count_3d_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BlockCount3DNotifier)
final blockCount3DProvider = BlockCount3DNotifierProvider._();

final class BlockCount3DNotifierProvider
    extends $NotifierProvider<BlockCount3DNotifier, BlockCount3DState> {
  BlockCount3DNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'blockCount3DProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$blockCount3DNotifierHash();

  @$internal
  @override
  BlockCount3DNotifier create() => BlockCount3DNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BlockCount3DState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BlockCount3DState>(value),
    );
  }
}

String _$blockCount3DNotifierHash() =>
    r'c5c768ebc1632a458210a3aeb432a253252c618e';

abstract class _$BlockCount3DNotifier extends $Notifier<BlockCount3DState> {
  BlockCount3DState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BlockCount3DState, BlockCount3DState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BlockCount3DState, BlockCount3DState>,
              BlockCount3DState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
