// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seismic_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SeismicNotifier)
final seismicProvider = SeismicNotifierProvider._();

final class SeismicNotifierProvider
    extends $NotifierProvider<SeismicNotifier, SeismicState> {
  SeismicNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'seismicProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$seismicNotifierHash();

  @$internal
  @override
  SeismicNotifier create() => SeismicNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SeismicState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SeismicState>(value),
    );
  }
}

String _$seismicNotifierHash() => r'79fff5b211406cee156101cd682e4b6c2b46acbf';

abstract class _$SeismicNotifier extends $Notifier<SeismicState> {
  SeismicState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SeismicState, SeismicState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SeismicState, SeismicState>,
              SeismicState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
