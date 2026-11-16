// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sum_snake_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SumSnakeNotifier)
final sumSnakeProvider = SumSnakeNotifierProvider._();

final class SumSnakeNotifierProvider
    extends $NotifierProvider<SumSnakeNotifier, SumSnakeState> {
  SumSnakeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sumSnakeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sumSnakeNotifierHash();

  @$internal
  @override
  SumSnakeNotifier create() => SumSnakeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SumSnakeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SumSnakeState>(value),
    );
  }
}

String _$sumSnakeNotifierHash() => r'aba6e37bdfde35158bbacb108e92fd2613a78b7d';

abstract class _$SumSnakeNotifier extends $Notifier<SumSnakeState> {
  SumSnakeState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SumSnakeState, SumSnakeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SumSnakeState, SumSnakeState>,
              SumSnakeState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
