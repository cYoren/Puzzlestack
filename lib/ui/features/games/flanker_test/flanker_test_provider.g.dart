// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flanker_test_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FlankerTestNotifier)
final flankerTestProvider = FlankerTestNotifierProvider._();

final class FlankerTestNotifierProvider
    extends $NotifierProvider<FlankerTestNotifier, FlankerTestState> {
  FlankerTestNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flankerTestProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flankerTestNotifierHash();

  @$internal
  @override
  FlankerTestNotifier create() => FlankerTestNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlankerTestState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlankerTestState>(value),
    );
  }
}

String _$flankerTestNotifierHash() =>
    r'dda810de2fb9ed7d59b45dbded6ea85aa051c401';

abstract class _$FlankerTestNotifier extends $Notifier<FlankerTestState> {
  FlankerTestState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FlankerTestState, FlankerTestState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FlankerTestState, FlankerTestState>,
              FlankerTestState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
