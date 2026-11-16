// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'divisibility_dash_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DivisibilityDashNotifier)
final divisibilityDashProvider = DivisibilityDashNotifierProvider._();

final class DivisibilityDashNotifierProvider
    extends $NotifierProvider<DivisibilityDashNotifier, DivisibilityDashState> {
  DivisibilityDashNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'divisibilityDashProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$divisibilityDashNotifierHash();

  @$internal
  @override
  DivisibilityDashNotifier create() => DivisibilityDashNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DivisibilityDashState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DivisibilityDashState>(value),
    );
  }
}

String _$divisibilityDashNotifierHash() =>
    r'899a1d112b738454bdbfb58e6e236615ceb022bd';

abstract class _$DivisibilityDashNotifier
    extends $Notifier<DivisibilityDashState> {
  DivisibilityDashState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DivisibilityDashState, DivisibilityDashState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DivisibilityDashState, DivisibilityDashState>,
              DivisibilityDashState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
