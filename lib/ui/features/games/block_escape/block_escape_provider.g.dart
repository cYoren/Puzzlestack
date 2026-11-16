// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block_escape_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BlockEscapeNotifier)
final blockEscapeProvider = BlockEscapeNotifierProvider._();

final class BlockEscapeNotifierProvider
    extends $NotifierProvider<BlockEscapeNotifier, BlockEscapeState> {
  BlockEscapeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'blockEscapeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$blockEscapeNotifierHash();

  @$internal
  @override
  BlockEscapeNotifier create() => BlockEscapeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BlockEscapeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BlockEscapeState>(value),
    );
  }
}

String _$blockEscapeNotifierHash() =>
    r'e625448fc61fb051a5ca29b24add6b281ada1924';

abstract class _$BlockEscapeNotifier extends $Notifier<BlockEscapeState> {
  BlockEscapeState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BlockEscapeState, BlockEscapeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BlockEscapeState, BlockEscapeState>,
              BlockEscapeState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
