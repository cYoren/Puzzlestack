// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'letter_bridge_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LetterBridgeNotifier)
final letterBridgeProvider = LetterBridgeNotifierProvider._();

final class LetterBridgeNotifierProvider
    extends $NotifierProvider<LetterBridgeNotifier, LetterBridgeState> {
  LetterBridgeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'letterBridgeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$letterBridgeNotifierHash();

  @$internal
  @override
  LetterBridgeNotifier create() => LetterBridgeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LetterBridgeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LetterBridgeState>(value),
    );
  }
}

String _$letterBridgeNotifierHash() =>
    r'ee5728050b2cac553ba3859a288f1b8f9bff4638';

abstract class _$LetterBridgeNotifier extends $Notifier<LetterBridgeState> {
  LetterBridgeState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LetterBridgeState, LetterBridgeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LetterBridgeState, LetterBridgeState>,
              LetterBridgeState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
