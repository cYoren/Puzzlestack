// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attentional_blink_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AttentionalBlinkNotifier)
final attentionalBlinkProvider = AttentionalBlinkNotifierProvider._();

final class AttentionalBlinkNotifierProvider
    extends $NotifierProvider<AttentionalBlinkNotifier, AttentionalBlinkState> {
  AttentionalBlinkNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'attentionalBlinkProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$attentionalBlinkNotifierHash();

  @$internal
  @override
  AttentionalBlinkNotifier create() => AttentionalBlinkNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AttentionalBlinkState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AttentionalBlinkState>(value),
    );
  }
}

String _$attentionalBlinkNotifierHash() =>
    r'92101125cf55e5a260504ce4d30e877716291086';

abstract class _$AttentionalBlinkNotifier
    extends $Notifier<AttentionalBlinkState> {
  AttentionalBlinkState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AttentionalBlinkState, AttentionalBlinkState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AttentionalBlinkState, AttentionalBlinkState>,
              AttentionalBlinkState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
