// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visual_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VisualSearchNotifier)
final visualSearchProvider = VisualSearchNotifierProvider._();

final class VisualSearchNotifierProvider
    extends $NotifierProvider<VisualSearchNotifier, VisualSearchState> {
  VisualSearchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visualSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visualSearchNotifierHash();

  @$internal
  @override
  VisualSearchNotifier create() => VisualSearchNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VisualSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VisualSearchState>(value),
    );
  }
}

String _$visualSearchNotifierHash() =>
    r'd0c118f537a6a8d01bd90a14fac8ec033310b28e';

abstract class _$VisualSearchNotifier extends $Notifier<VisualSearchState> {
  VisualSearchState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<VisualSearchState, VisualSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VisualSearchState, VisualSearchState>,
              VisualSearchState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
