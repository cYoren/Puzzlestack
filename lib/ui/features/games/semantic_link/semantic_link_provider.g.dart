// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semantic_link_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SemanticLinkNotifier)
final semanticLinkProvider = SemanticLinkNotifierProvider._();

final class SemanticLinkNotifierProvider
    extends $NotifierProvider<SemanticLinkNotifier, SemanticLinkState> {
  SemanticLinkNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'semanticLinkProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$semanticLinkNotifierHash();

  @$internal
  @override
  SemanticLinkNotifier create() => SemanticLinkNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SemanticLinkState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SemanticLinkState>(value),
    );
  }
}

String _$semanticLinkNotifierHash() =>
    r'f791ba58e1639bce7147f805c39992a80e668d63';

abstract class _$SemanticLinkNotifier extends $Notifier<SemanticLinkState> {
  SemanticLinkState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SemanticLinkState, SemanticLinkState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SemanticLinkState, SemanticLinkState>,
              SemanticLinkState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
