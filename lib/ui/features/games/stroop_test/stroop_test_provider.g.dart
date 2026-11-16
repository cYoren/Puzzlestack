// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stroop_test_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(StroopTestNotifier)
final stroopTestProvider = StroopTestNotifierProvider._();

final class StroopTestNotifierProvider
    extends $NotifierProvider<StroopTestNotifier, StroopTestState> {
  StroopTestNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stroopTestProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stroopTestNotifierHash();

  @$internal
  @override
  StroopTestNotifier create() => StroopTestNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StroopTestState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StroopTestState>(value),
    );
  }
}

String _$stroopTestNotifierHash() =>
    r'849ca3d0a54b4cd674f5657661b2cc470531c6cf';

abstract class _$StroopTestNotifier extends $Notifier<StroopTestState> {
  StroopTestState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<StroopTestState, StroopTestState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<StroopTestState, StroopTestState>,
              StroopTestState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
