// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radical_roots_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RadicalRootsNotifier)
final radicalRootsProvider = RadicalRootsNotifierProvider._();

final class RadicalRootsNotifierProvider
    extends $NotifierProvider<RadicalRootsNotifier, RadicalRootsState> {
  RadicalRootsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'radicalRootsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$radicalRootsNotifierHash();

  @$internal
  @override
  RadicalRootsNotifier create() => RadicalRootsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RadicalRootsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RadicalRootsState>(value),
    );
  }
}

String _$radicalRootsNotifierHash() =>
    r'534d2c09d28e713e10d9d7f1b00cb6d346ee57ea';

abstract class _$RadicalRootsNotifier extends $Notifier<RadicalRootsState> {
  RadicalRootsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RadicalRootsState, RadicalRootsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RadicalRootsState, RadicalRootsState>,
              RadicalRootsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
