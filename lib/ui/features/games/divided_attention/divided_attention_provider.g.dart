// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'divided_attention_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DividedAttentionNotifier)
final dividedAttentionProvider = DividedAttentionNotifierProvider._();

final class DividedAttentionNotifierProvider
    extends $NotifierProvider<DividedAttentionNotifier, DividedAttentionState> {
  DividedAttentionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dividedAttentionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dividedAttentionNotifierHash();

  @$internal
  @override
  DividedAttentionNotifier create() => DividedAttentionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DividedAttentionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DividedAttentionState>(value),
    );
  }
}

String _$dividedAttentionNotifierHash() =>
    r'7b1098294761d0cf8e84731bde9936fcf95c2fa3';

abstract class _$DividedAttentionNotifier
    extends $Notifier<DividedAttentionState> {
  DividedAttentionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DividedAttentionState, DividedAttentionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DividedAttentionState, DividedAttentionState>,
              DividedAttentionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
