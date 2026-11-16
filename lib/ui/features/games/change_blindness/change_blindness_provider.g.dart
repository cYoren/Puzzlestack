// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_blindness_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChangeBlindnessNotifier)
final changeBlindnessProvider = ChangeBlindnessNotifierProvider._();

final class ChangeBlindnessNotifierProvider
    extends $NotifierProvider<ChangeBlindnessNotifier, ChangeBlindnessState> {
  ChangeBlindnessNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'changeBlindnessProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$changeBlindnessNotifierHash();

  @$internal
  @override
  ChangeBlindnessNotifier create() => ChangeBlindnessNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChangeBlindnessState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChangeBlindnessState>(value),
    );
  }
}

String _$changeBlindnessNotifierHash() =>
    r'80c1843219692cba5e1bc7aba99932ef5c889458';

abstract class _$ChangeBlindnessNotifier
    extends $Notifier<ChangeBlindnessState> {
  ChangeBlindnessState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ChangeBlindnessState, ChangeBlindnessState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChangeBlindnessState, ChangeBlindnessState>,
              ChangeBlindnessState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
