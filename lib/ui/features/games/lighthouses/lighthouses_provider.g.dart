// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lighthouses_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LighthousesNotifier)
final lighthousesProvider = LighthousesNotifierProvider._();

final class LighthousesNotifierProvider
    extends $NotifierProvider<LighthousesNotifier, LighthousesState> {
  LighthousesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lighthousesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lighthousesNotifierHash();

  @$internal
  @override
  LighthousesNotifier create() => LighthousesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LighthousesState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LighthousesState>(value),
    );
  }
}

String _$lighthousesNotifierHash() =>
    r'b7ac4801ed255f83644cd6b1c54323213f647837';

abstract class _$LighthousesNotifier extends $Notifier<LighthousesState> {
  LighthousesState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LighthousesState, LighthousesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LighthousesState, LighthousesState>,
              LighthousesState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
