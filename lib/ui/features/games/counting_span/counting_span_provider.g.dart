// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'counting_span_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CountingSpanNotifier)
final countingSpanProvider = CountingSpanNotifierProvider._();

final class CountingSpanNotifierProvider
    extends $NotifierProvider<CountingSpanNotifier, CountingSpanState> {
  CountingSpanNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'countingSpanProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$countingSpanNotifierHash();

  @$internal
  @override
  CountingSpanNotifier create() => CountingSpanNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CountingSpanState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CountingSpanState>(value),
    );
  }
}

String _$countingSpanNotifierHash() =>
    r'048fa323558d7fd90dd05aaec4d10f88028468bf';

abstract class _$CountingSpanNotifier extends $Notifier<CountingSpanState> {
  CountingSpanState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CountingSpanState, CountingSpanState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CountingSpanState, CountingSpanState>,
              CountingSpanState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
