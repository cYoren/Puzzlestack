// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conjunction_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ConjunctionSearchNotifier)
final conjunctionSearchProvider = ConjunctionSearchNotifierProvider._();

final class ConjunctionSearchNotifierProvider
    extends
        $NotifierProvider<ConjunctionSearchNotifier, ConjunctionSearchState> {
  ConjunctionSearchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conjunctionSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conjunctionSearchNotifierHash();

  @$internal
  @override
  ConjunctionSearchNotifier create() => ConjunctionSearchNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConjunctionSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConjunctionSearchState>(value),
    );
  }
}

String _$conjunctionSearchNotifierHash() =>
    r'26dc742a0fc2966bb9a85f2e310c5021e05ac59b';

abstract class _$ConjunctionSearchNotifier
    extends $Notifier<ConjunctionSearchState> {
  ConjunctionSearchState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<ConjunctionSearchState, ConjunctionSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ConjunctionSearchState, ConjunctionSearchState>,
              ConjunctionSearchState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
