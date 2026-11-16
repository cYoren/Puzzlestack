// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semantic_distance_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SemanticDistanceNotifier)
final semanticDistanceProvider = SemanticDistanceNotifierProvider._();

final class SemanticDistanceNotifierProvider
    extends $NotifierProvider<SemanticDistanceNotifier, SemanticDistanceState> {
  SemanticDistanceNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'semanticDistanceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$semanticDistanceNotifierHash();

  @$internal
  @override
  SemanticDistanceNotifier create() => SemanticDistanceNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SemanticDistanceState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SemanticDistanceState>(value),
    );
  }
}

String _$semanticDistanceNotifierHash() =>
    r'ec86da3e74d87ab2a056123f06846e126b847e72';

abstract class _$SemanticDistanceNotifier
    extends $Notifier<SemanticDistanceState> {
  SemanticDistanceState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SemanticDistanceState, SemanticDistanceState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SemanticDistanceState, SemanticDistanceState>,
              SemanticDistanceState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
