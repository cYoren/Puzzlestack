// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'oxymoron_hunt_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OxymoronHuntNotifier)
final oxymoronHuntProvider = OxymoronHuntNotifierProvider._();

final class OxymoronHuntNotifierProvider
    extends $NotifierProvider<OxymoronHuntNotifier, OxymoronHuntState> {
  OxymoronHuntNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'oxymoronHuntProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$oxymoronHuntNotifierHash();

  @$internal
  @override
  OxymoronHuntNotifier create() => OxymoronHuntNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OxymoronHuntState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OxymoronHuntState>(value),
    );
  }
}

String _$oxymoronHuntNotifierHash() =>
    r'7e9ea8e02079b7d4fdf8aa74e1b540b7babeb0c7';

abstract class _$OxymoronHuntNotifier extends $Notifier<OxymoronHuntState> {
  OxymoronHuntState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<OxymoronHuntState, OxymoronHuntState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OxymoronHuntState, OxymoronHuntState>,
              OxymoronHuntState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
