// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inequality_dash_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(InequalityDashNotifier)
final inequalityDashProvider = InequalityDashNotifierProvider._();

final class InequalityDashNotifierProvider
    extends $NotifierProvider<InequalityDashNotifier, InequalityDashState> {
  InequalityDashNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inequalityDashProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inequalityDashNotifierHash();

  @$internal
  @override
  InequalityDashNotifier create() => InequalityDashNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InequalityDashState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InequalityDashState>(value),
    );
  }
}

String _$inequalityDashNotifierHash() =>
    r'd67ef98d59fd7f78f873607d349eace236871dbb';

abstract class _$InequalityDashNotifier extends $Notifier<InequalityDashState> {
  InequalityDashState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<InequalityDashState, InequalityDashState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InequalityDashState, InequalityDashState>,
              InequalityDashState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
