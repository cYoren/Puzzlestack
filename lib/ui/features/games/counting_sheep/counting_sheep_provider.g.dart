// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'counting_sheep_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CountingSheepNotifier)
final countingSheepProvider = CountingSheepNotifierProvider._();

final class CountingSheepNotifierProvider
    extends $NotifierProvider<CountingSheepNotifier, CountingSheepState> {
  CountingSheepNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'countingSheepProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$countingSheepNotifierHash();

  @$internal
  @override
  CountingSheepNotifier create() => CountingSheepNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CountingSheepState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CountingSheepState>(value),
    );
  }
}

String _$countingSheepNotifierHash() =>
    r'55b8115c3f43e50354c8b43a12aac87106118572';

abstract class _$CountingSheepNotifier extends $Notifier<CountingSheepState> {
  CountingSheepState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CountingSheepState, CountingSheepState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CountingSheepState, CountingSheepState>,
              CountingSheepState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
